#!/usr/bin/env python3
"""
SuiteV17 Plugin System - Moduli espandibili hot-pluggable
Carica, gestisce e orchestra plugin dinamicamente
"""
import os
import sys
import json
import importlib
import importlib.util
from pathlib import Path
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass, asdict
from datetime import datetime
from enum import Enum
import threading
import logging

logger = logging.getLogger(__name__)

class PluginState(Enum):
    REGISTERED = 'registered'
    LOADING = 'loading'
    ACTIVE = 'active'
    ERROR = 'error'
    DISABLED = 'disabled'
    UNLOADING = 'unloading'

@dataclass
class PluginManifest:
    """Manifesto plugin con metadati."""
    name: str
    version: str
    description: str
    author: str
    entry_point: str
    dependencies: List[str]
    hooks: List[str]
    permissions: List[str]
    min_suite_version: str
    state: PluginState = PluginState.REGISTERED
    loaded_at: Optional[str] = None
    error_message: Optional[str] = None

@dataclass
class PluginInstance:
    """Istanza plugin caricata."""
    manifest: PluginManifest
    module: Any
    instance: Any
    hooks: Dict[str, List[Callable]]
    state: PluginState

class HookRegistry:
    """Registro hook per eventi inter-plugin."""
    
    def __init__(self):
        self.hooks: Dict[str, List[tuple]] = {}  # event -> [(plugin_name, callback), ...]
        self._lock = threading.RLock()
    
    def register(self, event: str, plugin_name: str, callback: Callable):
        """Registra callback per evento."""
        with self._lock:
            if event not in self.hooks:
                self.hooks[event] = []
            self.hooks[event].append((plugin_name, callback))
            logger.debug(f'Hook registered: {event} by {plugin_name}')
    
    def unregister(self, event: str, plugin_name: str):
        """Rimuove tutti i hook di un plugin per un evento."""
        with self._lock:
            if event in self.hooks:
                self.hooks[event] = [(p, c) for p, c in self.hooks[event] if p != plugin_name]
    
    def unregister_all(self, plugin_name: str):
        """Rimuove tutti i hook di un plugin."""
        with self._lock:
            for event in self.hooks:
                self.hooks[event] = [(p, c) for p, c in self.hooks[event] if p != plugin_name]
    
    def emit(self, event: str, *args, **kwargs) -> List[Any]:
        """Emette evento a tutti i listener."""
        results = []
        with self._lock:
            listeners = self.hooks.get(event, []).copy()
        
        for plugin_name, callback in listeners:
            try:
                result = callback(*args, **kwargs)
                results.append({'plugin': plugin_name, 'result': result, 'error': None})
            except Exception as e:
                logger.error(f'Hook error in {plugin_name}.{event}: {e}')
                results.append({'plugin': plugin_name, 'result': None, 'error': str(e)})
        
        return results

class PluginManager:
    """Gestore plugin SuiteV17."""
    
    def __init__(self, plugins_dir: str = 'plugins'):
        self.plugins_dir = Path(plugins_dir)
        self.plugins_dir.mkdir(exist_ok=True)
        
        self.plugins: Dict[str, PluginInstance] = {}
        self.manifests: Dict[str, PluginManifest] = {}
        self.hooks = HookRegistry()
        
        # Crea directory plugin
        (self.plugins_dir / '__init__.py').touch()
        
        # Carica plugin builtin
        self._load_builtin_plugins()
    
    def _load_builtin_plugins(self):
        """Carica plugin builtin."""
        builtin_plugins = [
            'logging_plugin',
            'metrics_plugin',
            'health_check_plugin'
        ]
        
        for plugin_name in builtin_plugins:
            try:
                self.load_plugin(plugin_name, builtin=True)
            except Exception as e:
                logger.warning(f'Failed to load builtin plugin {plugin_name}: {e}')
    
    def scan_plugins(self) -> List[PluginManifest]:
        """Scansiona directory plugin e ritorna manifesti trovati."""
        manifests = []
        
        for plugin_dir in self.plugins_dir.iterdir():
            if not plugin_dir.is_dir():
                continue
            
            manifest_file = plugin_dir / 'plugin.json'
            if not manifest_file.exists():
                continue
            
            try:
                with open(manifest_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    manifest = PluginManifest(**data)
                    manifests.append(manifest)
            except Exception as e:
                logger.error(f'Failed to load manifest from {plugin_dir}: {e}')
        
        return manifests
    
    def load_plugin(self, plugin_name: str, builtin: bool = False) -> bool:
        """Carica un plugin."""
        if plugin_name in self.plugins:
            logger.warning(f'Plugin {plugin_name} already loaded')
            return False
        
        try:
            if builtin:
                return self._load_builtin_plugin(plugin_name)
            else:
                return self._load_external_plugin(plugin_name)
        except Exception as e:
            logger.error(f'Failed to load plugin {plugin_name}: {e}')
            return False
    
    def _load_builtin_plugin(self, plugin_name: str) -> bool:
        """Carica plugin builtin."""
        # Plugin builtin sono moduli Python nel package plugins
        try:
            module = importlib.import_module(f'plugins.{plugin_name}')
            manifest = PluginManifest(
                name=plugin_name,
                version=getattr(module, '__version__', '1.0.0'),
                description=getattr(module, '__doc__', 'Builtin plugin'),
                author='SuiteV17',
                entry_point=f'plugins.{plugin_name}',
                dependencies=[],
                hooks=getattr(module, 'HOOKS', []),
                permissions=[],
                min_suite_version='2.0.0',
                state=PluginState.LOADING
            )
            
            # Istanzia plugin
            plugin_class = getattr(module, 'Plugin', None)
            if plugin_class:
                instance = plugin_class()
                
                self.plugins[plugin_name] = PluginInstance(
                    manifest=manifest,
                    module=module,
                    instance=instance,
                    hooks={},
                    state=PluginState.ACTIVE
                )
                
                manifest.state = PluginState.ACTIVE
                manifest.loaded_at = datetime.now().isoformat()
                self.manifests[plugin_name] = manifest
                
                # Registra hook del plugin
                if hasattr(instance, 'register_hooks'):
                    instance.register_hooks(self.hooks)
                
                # Avvia plugin
                if hasattr(instance, 'start'):
                    instance.start()
                
                logger.info(f'Builtin plugin loaded: {plugin_name}')
                return True
            
        except Exception as e:
            logger.error(f'Failed to load builtin plugin {plugin_name}: {e}')
            return False
    
    def _load_external_plugin(self, plugin_name: str) -> bool:
        """Carica plugin esterno da directory."""
        plugin_dir = self.plugins_dir / plugin_name
        manifest_file = plugin_dir / 'plugin.json'
        
        if not manifest_file.exists():
            logger.error(f'Manifest not found for {plugin_name}')
            return False
        
        try:
            with open(manifest_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                manifest = PluginManifest(**data)
                manifest.state = PluginState.LOADING
            
            # Verifica dipendenze
            for dep in manifest.dependencies:
                if dep not in self.plugins:
                    logger.error(f'Dependency {dep} not found for {plugin_name}')
                    manifest.state = PluginState.ERROR
                    manifest.error_message = f'Missing dependency: {dep}'
                    self.manifests[plugin_name] = manifest
                    return False
            
            # Carica modulo
            entry_file = plugin_dir / manifest.entry_point
            spec = importlib.util.spec_from_file_location(plugin_name, entry_file)
            module = importlib.util.module_from_spec(spec)
            
            sys.path.insert(0, str(plugin_dir))
            spec.loader.exec_module(module)
            sys.path.pop(0)
            
            # Istanzia plugin
            plugin_class = getattr(module, 'Plugin', None)
            if not plugin_class:
                raise Exception(f'Plugin class not found in {plugin_name}')
            
            instance = plugin_class()
            
            # Registra hook
            if hasattr(instance, 'register_hooks'):
                instance.register_hooks(self.hooks)
            
            # Avvia plugin
            if hasattr(instance, 'start'):
                instance.start()
            
            self.plugins[plugin_name] = PluginInstance(
                manifest=manifest,
                module=module,
                instance=instance,
                hooks={},
                state=PluginState.ACTIVE
            )
            
            manifest.state = PluginState.ACTIVE
            manifest.loaded_at = datetime.now().isoformat()
            self.manifests[plugin_name] = manifest
            
            logger.info(f'External plugin loaded: {plugin_name} v{manifest.version}')
            return True
            
        except Exception as e:
            logger.error(f'Failed to load external plugin {plugin_name}: {e}')
            if plugin_name in self.manifests:
                self.manifests[plugin_name].state = PluginState.ERROR
                self.manifests[plugin_name].error_message = str(e)
            return False
    
    def unload_plugin(self, plugin_name: str) -> bool:
        """Scarica un plugin."""
        if plugin_name not in self.plugins:
            return False
        
        plugin = self.plugins[plugin_name]
        plugin.manifest.state = PluginState.UNLOADING
        
        try:
            # Chiama shutdown
            if hasattr(plugin.instance, 'stop'):
                plugin.instance.stop()
            
            # Rimuovi hook
            self.hooks.unregister_all(plugin_name)
            
            # Rimuovi da registry
            del self.plugins[plugin_name]
            plugin.manifest.state = PluginState.DISABLED
            
            logger.info(f'Plugin unloaded: {plugin_name}')
            return True
            
        except Exception as e:
            logger.error(f'Error unloading plugin {plugin_name}: {e}')
            plugin.manifest.state = PluginState.ERROR
            return False
    
    def reload_plugin(self, plugin_name: str) -> bool:
        """Ricarica un plugin."""
        if plugin_name in self.plugins:
            self.unload_plugin(plugin_name)
        return self.load_plugin(plugin_name)
    
    def get_plugin(self, name: str) -> Optional[PluginInstance]:
        """Ritorna istanza plugin."""
        return self.plugins.get(name)
    
    def get_all_plugins(self) -> List[PluginManifest]:
        """Ritorna tutti i manifest plugin."""
        return list(self.manifests.values())
    
    def call_plugin_method(self, plugin_name: str, method: str, *args, **kwargs) -> Any:
        """Chiama metodo su plugin."""
        plugin = self.plugins.get(plugin_name)
        if not plugin:
            raise Exception(f'Plugin {plugin_name} not found')
        
        if not hasattr(plugin.instance, method):
            raise Exception(f'Method {method} not found in plugin {plugin_name}')
        
        return getattr(plugin.instance, method)(*args, **kwargs)
    
    def emit(self, event: str, *args, **kwargs) -> List[Any]:
        """Emette evento a tutti i plugin."""
        return self.hooks.emit(event, *args, **kwargs)

# Esempio Plugin Base
class BasePlugin:
    """Classe base per plugin SuiteV17."""
    
    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)
    
    def register_hooks(self, registry: HookRegistry):
        """Registra hook - override in subclass."""
        pass
    
    def start(self):
        """Avvia plugin - override in subclass."""
        pass
    
    def stop(self):
        """Ferma plugin - override in subclass."""
        pass
    
    def get_info(self) -> Dict:
        """Ritorna info plugin."""
        return {
            'class': self.__class__.__name__,
            'module': self.__class__.__module__
        }

def main():
    """Demo plugin system."""
    print('SuiteV17 Plugin System Demo')
    print('=' * 50)
    
    pm = PluginManager()
    
    # Scansiona plugin disponibili
    manifests = pm.scan_plugins()
    print(f'\\nFound {len(manifests)} plugins')
    for m in manifests:
        print(f'  - {m.name} v{m.version}')
    
    # Mostra plugin caricati
    print(f'\\nLoaded plugins: {len(pm.get_all_plugins())}')
    for p in pm.get_all_plugins():
        print(f'  - {p.name} ({p.state.value})')

if __name__ == '__main__':
    main()

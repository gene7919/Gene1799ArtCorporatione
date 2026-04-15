#!/usr/bin/env python3
"""
Agente Correttore v2.0 - Analisi, Linting e Auto-Fix per SuiteV17
Dashboard-ready con API Flask e integrazione orchestratore
"""
import os
import sys
import json
import re
import subprocess
import ast
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional
from dataclasses import dataclass, asdict
from flask import Flask, request, jsonify
from flask_cors import CORS

sys.path.insert(0, r'C:\SuiteV17')

@dataclass
class ErrorReport:
    file: str
    line: int
    column: int
    severity: str  # error, warning, info
    code: str
    message: str
    suggestion: str
    fixed: bool = False

@dataclass
class CorrectionResult:
    file_path: str
    original_size: int
    fixed_size: int
    errors_found: int
    errors_fixed: int
    warnings: int
    changes: List[str]
    success: bool
    timestamp: str = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now().isoformat()

class PythonLinter:
    """Linter custom per file Python."""
    
    def __init__(self):
        self.errors: List[ErrorReport] = []
        
    def check_syntax(self, code: str, filename: str) -> bool:
        """Verifica sintassi Python."""
        self.errors = []
        try:
            ast.parse(code)
            return True
        except SyntaxError as e:
            self.errors.append(ErrorReport(
                file=filename,
                line=e.lineno or 1,
                column=e.offset or 0,
                severity='error',
                code='SYNTAX',
                message=str(e),
                suggestion='Correggere la sintassi del codice'
            ))
            return False
            
    def analyze_code(self, code: str, filename: str) -> List[ErrorReport]:
        """Analisi statica del codice."""
        lines = code.split('\n')
        defined_vars = set()
        used_vars = set()
        imported_names = set()
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Verifica linee troppo lunghe
            if len(line) > 120:
                self.errors.append(ErrorReport(
                    file=filename, line=i, column=120,
                    severity='warning', code='W001',
                    message='Linea troppo lunga (>120 caratteri)',
                    suggestion='Spezzare la linea o usare backslash'
                ))
                
            # Verifica spazi bianchi trailing
            if line != line.rstrip():
                self.errors.append(ErrorReport(
                    file=filename, line=i, column=len(line.rstrip()),
                    severity='info', code='I001',
                    message='Spazi bianchi in fondo alla linea',
                    suggestion='Rimuovere spazi trailing'
                ))
                
            # Verifica import non usati
            import_match = re.match(r'^import\s+(\w+)|^from\s+\S+\s+import\s+(.+)', stripped)
            if import_match:
                names = import_match.group(1) or import_match.group(2)
                if names:
                    imported_names.update(n.strip() for n in names.split(','))
                    
            # Traccia variabili
            var_match = re.match(r'^(\w+)\s*=', stripped)
            if var_match and not stripped.startswith('#'):
                defined_vars.add(var_match.group(1))
                
            for word in re.findall(r'\b[a-zA-Z_]\w*\b', stripped):
                if word not in ['def', 'class', 'if', 'for', 'while', 'return', 'import', 'from']:
                    used_vars.add(word)
        
        # Verifica import non usati
        unused_imports = imported_names - used_vars - {'os', 'sys', 'json', 'time', 'datetime'}
        for imp in unused_imports:
            self.errors.append(ErrorReport(
                file=filename, line=1, column=0,
                severity='warning', code='W002',
                message=f'Import potenzialmente non usato: {imp}',
                suggestion=f\"Verificare uso di {imp}\"
            ))
            
        return self.errors

class AutoFixer:
    """Applicatore automatico di correzioni."""
    
    def fix_trailing_whitespace(self, line: str) -> str:
        return line.rstrip()
        
    def fix_long_line(self, line: str) -> str:
        if len(line) > 120:
            return line[:117] + '...'
        return line
        
    def apply_fix(self, code: str, error: ErrorReport) -> Tuple[str, bool]:
        """Applica una correzione specifica."""
        lines = code.split('\n')
        if error.line <= 0 or error.line > len(lines):
            return code, False
            
        original_line = lines[error.line - 1]
        
        try:
            if error.code == 'I001':
                lines[error.line - 1] = self.fix_trailing_whitespace(original_line)
                return '\n'.join(lines), True
        except Exception:
            pass
                
        return code, False
        
    def auto_fix_all(self, code: str, errors: List[ErrorReport]) -> Tuple[str, int, List[str]]:
        """Applica tutti i fix automatici possibili."""
        fixes_applied = 0
        changes = []
        current_code = code
        
        for error in errors:
            if error.code in ['I001']:
                new_code, fixed = self.apply_fix(current_code, error)
                if fixed:
                    current_code = new_code
                    fixes_applied += 1
                    changes.append(f'Riga {error.line}: {error.message}')
                    
        return current_code, fixes_applied, changes

class AgenteCorrettore:
    """Agente correttore con API dashboard."""
    
    def __init__(self, root_path: str = r'C:\SuiteV17'):
        self.root_path = Path(root_path)
        self.linter = PythonLinter()
        self.fixer = AutoFixer()
        self.reports: List[CorrectionResult] = []
        self._lock = threading.Lock()
        
    def log(self, message: str):
        print(f'[{datetime.now().strftime("%H:%M:%S")}] {message}')
        
    def find_python_files(self, target_path: Path = None) -> List[Path]:
        """Trova tutti i file Python nel progetto."""
        files = []
        exclude = {'venv', '.venv', '__pycache__', 'node_modules', '.git', '.idea'}
        
        search_path = target_path or self.root_path
        for py_file in search_path.rglob('*.py'):
            if not any(ex in str(py_file) for ex in exclude):
                files.append(py_file)
        return files
        
    def analyze_file(self, file_path: Path) -> CorrectionResult:
        """Analizza e corregge un singolo file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_code = f.read()
        except Exception as e:
            return CorrectionResult(
                file_path=str(file_path),
                original_size=0, fixed_size=0,
                errors_found=0, errors_fixed=0, warnings=0,
                changes=[f'ERRORE LETTURA: {e}'], success=False
            )
            
        original_size = len(original_code)
        
        # Check sintassi
        if not self.linter.check_syntax(original_code, str(file_path)):
            return CorrectionResult(
                file_path=str(file_path),
                original_size=original_size, fixed_size=original_size,
                errors_found=len(self.linter.errors), errors_fixed=0,
                warnings=0, changes=[e.message for e in self.linter.errors],
                success=False
            )
            
        # Analisi completa
        errors = self.linter.analyze_code(original_code, str(file_path))
        
        # Applica fix automatici
        fixed_code, fixes_applied, changes = self.fixer.auto_fix_all(original_code, errors)
        
        # Salva file corretto
        if fixes_applied > 0:
            backup_path = str(file_path) + '.bak'
            try:
                with open(backup_path, 'w', encoding='utf-8') as f:
                    f.write(original_code)
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(fixed_code)
                changes.append(f'Backup: {backup_path}')
            except Exception as e:
                changes.append(f'ERRORE SCRITTURA: {e}')
                
        warnings = len([e for e in errors if e.severity == 'warning'])
        
        return CorrectionResult(
            file_path=str(file_path),
            original_size=original_size,
            fixed_size=len(fixed_code),
            errors_found=len(errors),
            errors_fixed=fixes_applied,
            warnings=warnings,
            changes=changes,
            success=True
        )
        
    def correggi_cartella(self, folder_path: str = None) -> Dict:
        """Corregge tutti i file Python in una cartella."""
        folder = Path(folder_path) if folder_path else self.root_path
        if not folder.exists():
            return {'error': f'Cartella non trovata: {folder_path}'}
            
        with self._lock:
            self.reports = []
            py_files = self.find_python_files(folder)
            
            for py_file in py_files:
                report = self.analyze_file(py_file)
                self.reports.append(report)
                
        return self.get_summary()
        
    def get_summary(self) -> Dict:
        """Genera report riassuntivo."""
        total_errors = sum(r.errors_found for r in self.reports)
        total_fixed = sum(r.errors_fixed for r in self.reports)
        
        return {
            'files_analyzed': len(self.reports),
            'errors_found': total_errors,
            'errors_fixed': total_fixed,
            'files_modified': sum(1 for r in self.reports if r.errors_fixed > 0),
            'reports': [asdict(r) for r in self.reports]
        }
        
    def generate_json_report(self) -> str:
        return json.dumps(self.get_summary(), indent=2, default=str)

# Flask API per dashboard
app = Flask(__name__)
CORS(app)

correttore = AgenteCorrettore()

@app.route('/api/correttore/status')
def api_status():
    return jsonify({
        'status': 'online',
        'files_analyzed': len(correttore.reports),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/correttore/analyze', methods=['POST'])
def analyze():
    data = request.json or {}
    folder = data.get('folder', r'C:\SuiteV17')
    result = correttore.correggi_cartella(folder)
    return jsonify(result)

@app.route('/api/correttore/summary')
def summary():
    return jsonify(correttore.get_summary())

@app.route('/api/correttore/file', methods=['POST'])
def analyze_single_file():
    data = request.json or {}
    file_path = data.get('file')
    if not file_path:
        return jsonify({'error': 'File path required'}), 400
    result = correttore.analyze_file(Path(file_path))
    return jsonify(asdict(result))

def main():
    if len(sys.argv) < 2:
        print('Uso: python agent_correttore.py [cartella|api]')
        print('  api: Avvia server API su porta 3020')
        sys.exit(1)
        
    if sys.argv[1] == 'api':
        print('Agente Correttore API Server - Porta 3020')
        app.run(host='0.0.0.0', port=3020, debug=False)
    else:
        agente = AgenteCorrettore()
        report = agente.correggi_cartella(sys.argv[1])
        print(json.dumps(report, indent=2, default=str))

if __name__ == '__main__':
    main()

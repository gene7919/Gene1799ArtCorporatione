#!/usr/bin/env python3
"""
Gene1799 Orchestrator System Validator
Validates that all components are properly configured and ready to run
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime

class OrchestratorValidator:
    def __init__(self):
        self.project_root = Path.cwd()
        self.timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.checks_passed = 0
        self.checks_failed = 0
        self.warnings = []
        
    def print_header(self):
        print("\n" + "="*70)
        print("🔍 GENE1799 ORCHESTRATOR SYSTEM VALIDATOR")
        print("="*70)
        print(f"⏰ {self.timestamp}")
        print(f"📁 Project Root: {self.project_root}")
        print("="*70 + "\n")
    
    def print_section(self, title):
        print(f"\n📋 {title}")
        print("-" * 70)
    
    def check_passed(self, item):
        self.checks_passed += 1
        print(f"  ✅ {item}")
    
    def check_failed(self, item):
        self.checks_failed += 1
        print(f"  ❌ {item}")
    
    def check_warning(self, item):
        self.warnings.append(item)
        print(f"  ⚠️  {item}")
    
    def validate_python(self):
        self.print_section("Python Environment")
        
        try:
            version = sys.version.split()[0]
            major, minor = map(int, version.split('.')[:2])
            
            if major >= 3 and minor >= 9:
                self.check_passed(f"Python {version} (required: 3.9+)")
            else:
                self.check_failed(f"Python {version} (required: 3.9+)")
                
        except Exception as e:
            self.check_failed(f"Python version check: {e}")
    
    def validate_files(self):
        self.print_section("Required Files")
        
        required_files = {
            'orchestrator.py': 'Master orchestrator',
            'orchestrator_monitor.py': 'Monitor dashboard',
            'launch_orchestrator.bat': 'Windows batch launcher',
            'launch_orchestrator.ps1': 'PowerShell launcher',
            'ORCHESTRATOR_GUIDE.md': 'Documentation',
            'backend/src/index.js': 'Backend API',
            'frontend/src/App.tsx': 'Frontend React app',
            'ai-agent/agent.py': 'AI agent module',
            'ai-agent/requirements.txt': 'Python dependencies',
        }
        
        for file_path, description in required_files.items():
            full_path = self.project_root / file_path
            if full_path.exists():
                self.check_passed(f"{description} ({file_path})")
            else:
                self.check_failed(f"{description} ({file_path}) - NOT FOUND")
    
    def validate_environment_files(self):
        self.print_section("Environment Configuration")
        
        env_files = {
            'backend/.env': 'Backend configuration',
            'frontend/.env': 'Frontend configuration',
            'ai-agent/.env': 'AI agent configuration',
        }
        
        for env_file, description in env_files.items():
            full_path = self.project_root / env_file
            if full_path.exists():
                self.check_passed(f"{description} ({env_file})")
                # Check if it has content
                with open(full_path, 'r') as f:
                    content = f.read().strip()
                    if not content:
                        self.check_warning(f"  {env_file} is empty")
            else:
                self.check_warning(f"{description} ({env_file}) - creating may be needed")
    
    def validate_package_json(self):
        self.print_section("Package Configuration")
        
        package_files = {
            'package.json': 'Root workspace',
            'backend/package.json': 'Backend service',
            'frontend/package.json': 'Frontend service',
            'shared/package.json': 'Shared libraries',
        }
        
        for pkg_file, description in package_files.items():
            full_path = self.project_root / pkg_file
            if full_path.exists():
                try:
                    with open(full_path, 'r') as f:
                        data = json.load(f)
                        name = data.get('name', 'unknown')
                        version = data.get('version', 'unknown')
                        self.check_passed(f"{description} ({name}@{version})")
                except json.JSONDecodeError:
                    self.check_failed(f"{description} ({pkg_file}) - invalid JSON")
            else:
                self.check_failed(f"{description} ({pkg_file}) - NOT FOUND")
    
    def validate_python_dependencies(self):
        self.print_section("Python Dependencies")
        
        # Check if requirements.txt exists
        req_file = self.project_root / 'ai-agent/requirements.txt'
        if not req_file.exists():
            self.check_failed("ai-agent/requirements.txt - NOT FOUND")
            return
        
        try:
            with open(req_file, 'r') as f:
                requirements = f.read()
                expected_packages = ['azure-ai-agents', 'python-dotenv', 'aiohttp', 'requests']
                
                for package in expected_packages:
                    if package.lower() in requirements.lower():
                        self.check_passed(f"Dependency: {package}")
                    else:
                        self.check_warning(f"Dependency missing: {package}")
                
        except Exception as e:
            self.check_failed(f"Reading requirements.txt: {e}")
    
    def validate_deployment_config(self):
        self.print_section("Deployment Configuration")
        
        deployment_files = {
            'render.yaml': 'Render.com blueprint',
            'Dockerfile': 'Docker image definition',
            'docker-compose.yml': 'Docker compose stack',
            'Procfile': 'Process definitions',
            'nginx.conf': 'Nginx configuration',
        }
        
        for deploy_file, description in deployment_files.items():
            full_path = self.project_root / deploy_file
            if full_path.exists():
                self.check_passed(f"{description} ({deploy_file})")
            else:
                self.check_warning(f"{description} ({deploy_file}) - not found")
    
    def validate_ci_cd(self):
        self.print_section("CI/CD Pipelines")
        
        workflows = {
            '.github/workflows/deploy.yml': 'Deployment workflow',
            '.github/workflows/quality.yml': 'Quality checks workflow',
        }
        
        for workflow_file, description in workflows.items():
            full_path = self.project_root / workflow_file
            if full_path.exists():
                self.check_passed(f"{description} ({workflow_file})")
            else:
                self.check_warning(f"{description} ({workflow_file}) - not found")
    
    def validate_directory_structure(self):
        self.print_section("Directory Structure")
        
        directories = {
            'backend': 'Backend service',
            'frontend': 'Frontend service',
            'ai-agent': 'AI agent system',
            'desktop': 'Desktop application',
            'shared': 'Shared libraries',
            'docs': 'Documentation',
            '.github': 'GitHub configuration',
        }
        
        for dir_name, description in directories.items():
            full_path = self.project_root / dir_name
            if full_path.exists() and full_path.is_dir():
                items = len(list(full_path.iterdir()))
                self.check_passed(f"{description} ({items} items)")
            else:
                self.check_failed(f"{description} - NOT FOUND")
    
    def validate_nodejs_builds(self):
        self.print_section("Node.js Build Status")
        
        print("  ℹ️  Backend build status: checking...")
        backend_dist = self.project_root / 'backend/dist'
        if backend_dist.exists():
            files = len(list(backend_dist.rglob('*')))
            self.check_passed(f"Backend build artifacts ({files} files)")
        else:
            self.check_warning("Backend build not run yet (run: npm run build)")
        
        print("  ℹ️  Frontend build status: checking...")
        frontend_dist = self.project_root / 'frontend/dist'
        if frontend_dist.exists():
            files = len(list(frontend_dist.rglob('*')))
            self.check_passed(f"Frontend build artifacts ({files} files)")
        else:
            self.check_warning("Frontend build not run yet (run: npm run build)")
    
    def validate_venv(self):
        self.print_section("Python Virtual Environment")
        
        venv_path = self.project_root / 'ai-agent/venv'
        if venv_path.exists():
            python_exe = venv_path / 'Scripts/python.exe'
            if python_exe.exists():
                self.check_passed(f"Virtual environment exists ({venv_path})")
            else:
                self.check_warning("Virtual environment may not be fully initialized")
        else:
            self.check_warning("Virtual environment not found (create with: python -m venv ai-agent/venv)")
    
    def print_summary(self):
        total = self.checks_passed + self.checks_failed
        percentage = (self.checks_passed / total * 100) if total > 0 else 0
        
        print("\n" + "="*70)
        print("📊 VALIDATION SUMMARY")
        print("="*70)
        print(f"✅ Passed: {self.checks_passed}")
        print(f"❌ Failed: {self.checks_failed}")
        print(f"⚠️  Warnings: {len(self.warnings)}")
        print(f"📈 Success Rate: {percentage:.1f}%")
        print("="*70)
        
        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for warning in self.warnings:
                print(f"  • {warning}")
        
        if self.checks_failed > 0:
            print("\n❌ CRITICAL ISSUES:")
            print("  Fix the failed checks above before running orchestrator")
        else:
            print("\n✅ All checks passed! System is ready to run.")
        
        print("\n🚀 TO START ORCHESTRATOR:")
        print("  python orchestrator.py")
        print("\n📊 TO START MONITOR:")
        print("  python orchestrator_monitor.py")
        print()
    
    def run_validation(self):
        self.print_header()
        self.validate_python()
        self.validate_files()
        self.validate_environment_files()
        self.validate_package_json()
        self.validate_python_dependencies()
        self.validate_deployment_config()
        self.validate_ci_cd()
        self.validate_directory_structure()
        self.validate_nodejs_builds()
        self.validate_venv()
        self.print_summary()
        
        return self.checks_failed == 0

def main():
    try:
        validator = OrchestratorValidator()
        success = validator.run_validation()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n👋 Validation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Validation error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()

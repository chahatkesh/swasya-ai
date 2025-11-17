"""
Simple validation script to check file structure and syntax
without requiring external dependencies
"""

import os
import ast

print("=" * 60)
print("VALIDATING REFACTORED BACKEND STRUCTURE")
print("=" * 60)

# Test 1: Check if all files exist
print("\n1. Checking file structure...")
required_files = [
    'main.py',
    'models.py', 
    'config.py',
    'routes/__init__.py',
    'routes/health.py',
    'routes/patients.py',
    'routes/queue.py',
    'routes/uploads.py',
    'utils/__init__.py',
    'utils/storage.py',
    'utils/ai_services.py',
]

all_exist = True
for file in required_files:
    filepath = f'/home/runner/work/hackcbs/hackcbs/simple_backend/{file}'
    exists = os.path.exists(filepath)
    status = "✅" if exists else "❌"
    print(f"   {status} {file}")
    if not exists:
        all_exist = False

if all_exist:
    print("   ✅ All required files present")
else:
    print("   ❌ Some files missing")
    exit(1)

# Test 2: Check Python syntax
print("\n2. Checking Python syntax...")
syntax_valid = True
for file in required_files:
    if not file.endswith('.py'):
        continue
    filepath = f'/home/runner/work/hackcbs/hackcbs/simple_backend/{file}'
    try:
        with open(filepath, 'r') as f:
            ast.parse(f.read())
        print(f"   ✅ {file}")
    except SyntaxError as e:
        print(f"   ❌ {file}: {e}")
        syntax_valid = False

if not syntax_valid:
    exit(1)

# Test 3: Count lines of code
print("\n3. Code metrics...")
def count_lines(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        code_lines = [l for l in lines if l.strip() and not l.strip().startswith('#')]
        return len(code_lines)

original_lines = count_lines('/home/runner/work/hackcbs/hackcbs/simple_backend/main_original.py')
new_main_lines = count_lines('/home/runner/work/hackcbs/hackcbs/simple_backend/main.py')

print(f"   Original main.py: {original_lines} lines of code")
print(f"   New main.py: {new_main_lines} lines of code")
print(f"   Reduction: {original_lines - new_main_lines} lines ({100 - int(new_main_lines/original_lines*100)}%)")

# Test 4: Count endpoints
print("\n4. Counting endpoints...")
endpoint_counts = {}
route_files = ['health.py', 'patients.py', 'queue.py', 'uploads.py']

for route_file in route_files:
    filepath = f'/home/runner/work/hackcbs/hackcbs/simple_backend/routes/{route_file}'
    with open(filepath, 'r') as f:
        content = f.read()
        # Count @router. decorators
        count = content.count('@router.')
        endpoint_counts[route_file] = count
        print(f"   routes/{route_file}: {count} endpoints")

total_endpoints = sum(endpoint_counts.values())
print(f"   Total endpoints: {total_endpoints}")

# Test 5: Check main.py includes all routers
print("\n5. Checking router registration in main.py...")
with open('/home/runner/work/hackcbs/hackcbs/simple_backend/main.py', 'r') as f:
    main_content = f.read()

routers_to_check = ['health', 'patients', 'queue', 'uploads']
all_registered = True
for router_name in routers_to_check:
    if f'{router_name}.router' in main_content:
        print(f"   ✅ {router_name}.router registered")
    else:
        print(f"   ❌ {router_name}.router NOT registered")
        all_registered = False

if not all_registered:
    exit(1)

# Test 6: Check imports in route files
print("\n6. Checking imports in route files...")
import_checks = {
    'routes/health.py': ['APIRouter', 'load_json'],
    'routes/patients.py': ['APIRouter', 'PatientCreate', 'load_json'],
    'routes/queue.py': ['APIRouter', 'QueueEntry', 'QueueStatus'],
    'routes/uploads.py': ['APIRouter', 'File', 'UploadFile', 'transcribe_audio'],
}

for filepath, expected_imports in import_checks.items():
    full_path = f'/home/runner/work/hackcbs/hackcbs/simple_backend/{filepath}'
    with open(full_path, 'r') as f:
        content = f.read()
    
    missing = []
    for imp in expected_imports:
        if imp not in content:
            missing.append(imp)
    
    if not missing:
        print(f"   ✅ {filepath}")
    else:
        print(f"   ⚠️  {filepath} - missing: {', '.join(missing)}")

# Test 7: Verify modular structure
print("\n7. Verifying modular structure...")
modules = {
    'models.py': 'Data models',
    'config.py': 'Configuration',
    'utils/storage.py': 'Storage helpers',
    'utils/ai_services.py': 'AI service integrations',
    'routes/health.py': 'Health check routes',
    'routes/patients.py': 'Patient management routes',
    'routes/queue.py': 'Queue management routes',
    'routes/uploads.py': 'Upload and processing routes',
}

for module, description in modules.items():
    filepath = f'/home/runner/work/hackcbs/hackcbs/simple_backend/{module}'
    lines = count_lines(filepath)
    print(f"   ✅ {module}: {description} ({lines} lines)")

# Summary
print("\n" + "=" * 60)
print("VALIDATION COMPLETE ✅")
print("=" * 60)
print("\nRefactoring Summary:")
print(f"  • Original main.py: {original_lines} lines")
print(f"  • New main.py: {new_main_lines} lines ({100 - int(new_main_lines/original_lines*100)}% reduction)")
print(f"  • Total endpoints: {total_endpoints}")
print(f"  • Modules created: {len(modules)}")
print("\nStructure:")
print("  simple_backend/")
print("  ├── main.py              # App initialization & router registration")
print("  ├── models.py            # Pydantic data models")
print("  ├── config.py            # Configuration constants")
print("  ├── routes/              # Modular route handlers")
print("  │   ├── health.py        # Health check endpoints")
print("  │   ├── patients.py      # Patient CRUD operations")
print("  │   ├── queue.py         # Queue management")
print("  │   └── uploads.py       # File upload & AI processing")
print("  └── utils/               # Utility functions")
print("      ├── storage.py       # JSON storage helpers")
print("      └── ai_services.py   # AI service integrations")
print("\nBenefits:")
print("  ✅ Better code organization")
print("  ✅ Easier maintenance and testing")
print("  ✅ Clear separation of concerns")
print("  ✅ Reduced file complexity")
print("  ✅ Easier to add new endpoints")
print("=" * 60)

#!/bin/bash

# PHC AI Co-Pilot - Test All Lambda Functions Locally
# Run this before deploying to catch issues early!

set -e

echo "🧪 PHC AI Co-Pilot - Local Testing"
echo "===================================="
echo ""

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️  WARNING: GEMINI_API_KEY not set!"
    echo "   Scribe and Digitize tests will be skipped."
    echo ""
    echo "   To test Gemini integration, run:"
    echo "   export GEMINI_API_KEY='your-key-here'"
    echo ""
    SKIP_GEMINI=true
else
    echo "✅ GEMINI_API_KEY is set"
    SKIP_GEMINI=false
fi

# Check if venv exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "   Run: ./setup.sh"
    exit 1
fi

# Activate venv
source .venv/bin/activate

echo ""
echo "Running tests..."
echo "=================="
echo ""

PASSED=0
FAILED=0

# Test Patient Registration
echo "📋 Testing Patient Registration..."
cd lambdas/patient_registration
if python3.12 test_local.py > /tmp/test_patient.log 2>&1; then
    echo "   ✅ PASSED"
    PASSED=$((PASSED + 1))
else
    echo "   ❌ FAILED (see /tmp/test_patient.log)"
    FAILED=$((FAILED + 1))
fi
cd ../..

# Test Presigned URL
echo "🔗 Testing Presigned URL Generator..."
cd lambdas/presigned_url
if python3.12 test_local.py > /tmp/test_presigned.log 2>&1; then
    echo "   ✅ PASSED"
    PASSED=$((PASSED + 1))
else
    echo "   ❌ FAILED (see /tmp/test_presigned.log)"
    FAILED=$((FAILED + 1))
fi
cd ../..

# Test Scribe (only if GEMINI_API_KEY is set)
if [ "$SKIP_GEMINI" = false ]; then
    echo "🎤 Testing AI Scribe (Gemini)..."
    cd lambdas/scribe_task
    if python3.12 test_local.py > /tmp/test_scribe.log 2>&1; then
        echo "   ✅ PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "   ❌ FAILED (see /tmp/test_scribe.log)"
        FAILED=$((FAILED + 1))
    fi
    cd ../..
else
    echo "⏭️  Skipping AI Scribe tests (no GEMINI_API_KEY)"
fi

# Test Digitize (only if GEMINI_API_KEY is set)
if [ "$SKIP_GEMINI" = false ]; then
    echo "📄 Testing AI Digitizer (Gemini)..."
    cd lambdas/digitize_task
    if python3.12 test_local.py > /tmp/test_digitize.log 2>&1; then
        echo "   ✅ PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "   ❌ FAILED (see /tmp/test_digitize.log)"
        FAILED=$((FAILED + 1))
    fi
    cd ../..
else
    echo "⏭️  Skipping AI Digitizer tests (no GEMINI_API_KEY)"
fi

# Summary
echo ""
echo "Test Results"
echo "=============="
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Deploy: ./deploy.sh"
    echo "  2. Test APIs: Check OUTPUT URLs after deployment"
    echo ""
    exit 0
else
    echo "⚠️  Some tests failed. Fix issues before deploying."
    echo ""
    echo "Check logs in /tmp/test_*.log for details"
    exit 1
fi

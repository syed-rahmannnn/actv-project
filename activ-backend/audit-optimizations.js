/**
 * COMPREHENSIVE API OPTIMIZATION AUDIT
 * Checks all routes for optimization patterns
 */

const fs = require('fs');
const path = require('path');

const routesDir = path.join(__dirname, 'routes');

// Optimization patterns to check
const optimizationPatterns = {
    lean: /\.lean\(\)/g,
    select: /\.select\(/g,
    parallelQueries: /Promise\.all\(/g,
    timeout: /maxTimeMS\(/g,
    indexedFields: /memberId:|companyId:|email:/g
};

// Anti-patterns to flag
const antiPatterns = {
    noLean: /\.(find|findOne|findById)\([^)]*\)(?!\s*\.lean)/g,
    sequentialQueries: /await.*\n.*await.*\n.*await/g,
    longTimeouts: /maxTimeMS\((1[0-9]{4,}|[2-9][0-9]{4,})\)/g, // > 10 seconds
    retryLoops: /while.*retry|for.*retry/gi
};

function analyzeFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    const fileName = path.basename(filePath);

    const results = {
        file: fileName,
        optimizations: {},
        issues: {},
        score: 0
    };

    // Check for optimizations
    for (const [name, pattern] of Object.entries(optimizationPatterns)) {
        const matches = content.match(pattern);
        results.optimizations[name] = matches ? matches.length : 0;
        if (matches) results.score += matches.length;
    }

    // Check for anti-patterns
    for (const [name, pattern] of Object.entries(antiPatterns)) {
        const matches = content.match(pattern);
        if (matches) {
            results.issues[name] = matches.length;
            results.score -= matches.length * 2; // Penalize heavily
        }
    }

    return results;
}

function generateReport() {
    console.log('='.repeat(80));
    console.log('🔍 COMPREHENSIVE API OPTIMIZATION AUDIT');
    console.log('='.repeat(80));
    console.log('\n📂 Scanning routes directory...\n');

    const files = fs.readdirSync(routesDir)
        .filter(f => f.endsWith('.js'))
        .map(f => path.join(routesDir, f));

    const results = files.map(analyzeFile);

    // Sort by score (lowest first - needs most work)
    results.sort((a, b) => a.score - b.score);

    console.log('📊 OPTIMIZATION SCORES (Higher is better)\n');
    console.log('File'.padEnd(30) + 'Score'.padEnd(10) + 'Status');
    console.log('-'.repeat(80));

    results.forEach(r => {
        const status = r.score >= 10 ? '✅ EXCELLENT' :
            r.score >= 5 ? '✅ GOOD' :
            r.score >= 0 ? '⚠️  NEEDS WORK' :
            '❌ CRITICAL';
        console.log(r.file.padEnd(30) + r.score.toString().padEnd(10) + status);
    });

    console.log('\n' + '='.repeat(80));
    console.log('📈 DETAILED ANALYSIS\n');

    results.forEach(r => {
        console.log(`\n📄 ${r.file}`);
        console.log('   Optimizations:');
        console.log(`      • .lean() calls: ${r.optimizations.lean}`);
        console.log(`      • .select() calls: ${r.optimizations.select}`);
        console.log(`      • Promise.all() usage: ${r.optimizations.parallelQueries}`);
        console.log(`      • Query timeouts: ${r.optimizations.timeout}`);

        if (Object.keys(r.issues).length > 0) {
            console.log('   ⚠️  Issues found:');
            for (const [issue, count] of Object.entries(r.issues)) {
                console.log(`      • ${issue}: ${count} occurrences`);
            }
        } else {
            console.log('   ✅ No issues found');
        }
    });

    console.log('\n' + '='.repeat(80));
    console.log('📊 SUMMARY STATISTICS\n');

    const totalLean = results.reduce((sum, r) => sum + r.optimizations.lean, 0);
    const totalSelect = results.reduce((sum, r) => sum + r.optimizations.select, 0);
    const totalParallel = results.reduce((sum, r) => sum + r.optimizations.parallelQueries, 0);
    const avgScore = results.reduce((sum, r) => sum + r.score, 0) / results.length;

    console.log(`   Total .lean() calls: ${totalLean}`);
    console.log(`   Total .select() calls: ${totalSelect}`);
    console.log(`   Total Promise.all(): ${totalParallel}`);
    console.log(`   Average score: ${avgScore.toFixed(1)}`);

    const excellent = results.filter(r => r.score >= 10).length;
    const good = results.filter(r => r.score >= 5 && r.score < 10).length;
    const needsWork = results.filter(r => r.score >= 0 && r.score < 5).length;
    const critical = results.filter(r => r.score < 0).length;

    console.log(`\n   ✅ Excellent routes: ${excellent}/${results.length}`);
    console.log(`   ✅ Good routes: ${good}/${results.length}`);
    console.log(`   ⚠️  Needs work: ${needsWork}/${results.length}`);
    console.log(`   ❌ Critical: ${critical}/${results.length}`);

    console.log('\n' + '='.repeat(80));
    console.log('🎯 RECOMMENDATIONS\n');

    const needsOptimization = results.filter(r => r.score < 5);
    if (needsOptimization.length === 0) {
        console.log('   🎉 All routes are well optimized!');
        console.log('   ✅ No further action required.');
    } else {
        console.log('   Routes that need optimization:\n');
        needsOptimization.forEach(r => {
            console.log(`   📝 ${r.file}:`);
            if (r.optimizations.lean === 0) {
                console.log('      • Add .lean() to queries for 40% performance boost');
            }
            if (r.optimizations.select === 0) {
                console.log('      • Add .select() to fetch only needed fields');
            }
            if (r.optimizations.parallelQueries === 0) {
                console.log('      • Use Promise.all() for parallel queries');
            }
            if (r.issues.retryLoops) {
                console.log('      • Remove retry loops (use single query with timeout)');
            }
            console.log('');
        });
    }

    console.log('='.repeat(80));
}

try {
    generateReport();
} catch (error) {
    console.error('❌ Audit failed:', error);
    process.exit(1);
}
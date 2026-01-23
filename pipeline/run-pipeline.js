const AnticancerAIEngine = require('./anticancer-ai-engine');
const engine = new AnticancerAIEngine('gene1799', 'italy');

(async () => {
    const chelanti = require('./metals-data/multi-target-chelants.json').chelanti;
    for (const c of chelanti) {
        await engine.optimizeChelator(c);
    }
})();

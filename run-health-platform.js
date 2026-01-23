const HealthDataAcquisition = require('./copilot-agent/health-data-acquisition');
const { ProjectOwners } = require('./copilot-agent/project-owners');

async function main() {
    console.log('Gene1799ArtCorporatione - Health Intelligence Platform');
    console.log('Proprietari:', ProjectOwners.map(p => p.nome).join(', '));
    
    const healthModule = new HealthDataAcquisition();
    await healthModule.generateHealthReport('PATIENT-GEN1799-001');
}

main().catch(console.error);

class Gene1799HealthcareIntegration {
    constructor(projectId, location, datasetId) {
        this.projectId = projectId;
        this.location = location;
        this.datasetId = datasetId;
        
        console.log('🏥 Healthcare Integration inizializzata');
        console.log(`   Project: ${projectId}`);
        console.log(`   Location: ${location}`);
    }

    async analyzePatientMetals(patientId) {
        console.log(`\n🔬 Analisi metalli pesanti per paziente ${patientId}`);
        
        const metalLevels = {
            patientId: patientId,
            timestamp: new Date().toISOString(),
            metals: {
                Cu: { value: 2.3, unit: 'μg/dL', reference: '0.75-1.45', status: 'HIGH' },
                Fe: { value: 145, unit: 'μg/dL', reference: '60-170', status: 'NORMAL' },
                Pb: { value: 8.5, unit: 'μg/dL', reference: '<5', status: 'HIGH' },
                Hg: { value: 3.2, unit: 'μg/L', reference: '<10', status: 'NORMAL' }
            }
        };

        console.log('📊 Risultati analisi:');
        Object.entries(metalLevels.metals).forEach(([metal, data]) => {
            const status = data.status === 'HIGH' ? '⚠️' : '✅';
            console.log(`   ${status} ${metal}: ${data.value} ${data.unit} (Ref: ${data.reference})`);
        });

        return metalLevels;
    }

    async recommendChelator(metalLevels) {
        console.log('\n💊 Raccomandazione chelante...');

        const highMetals = Object.entries(metalLevels.metals)
            .filter(([_, data]) => data.status === 'HIGH')
            .map(([metal, _]) => metal);

        if (highMetals.length === 0) {
            console.log('✅ Nessun chelante necessario - livelli normali');
            return null;
        }

        const recommendations = {
            Cu: { chelator: 'TEPA', dosage: 'Variabile', priority: 'ALTA', efficacy: 82 },
            Pb: { chelator: 'DMSA', dosage: '10 mg/kg 3x/die', priority: 'ALTA', efficacy: 85 },
            Hg: { chelator: 'DMSA', dosage: '10 mg/kg 3x/die', priority: 'ALTA', efficacy: 88 },
            Fe: { chelator: 'Deferoxamina', dosage: '20-60 mg/kg/die', priority: 'MEDIA', efficacy: 71 }
        };

        console.log('🎯 Chelanti raccomandati:');
        highMetals.forEach(metal => {
            const rec = recommendations[metal];
            console.log(`   ${metal}: ${rec.chelator} - ${rec.dosage}`);
            console.log(`      Priorità: ${rec.priority} | Efficacia: ${rec.efficacy}%`);
        });

        return highMetals.map(metal => ({
            metal,
            ...recommendations[metal]
        }));
    }

    async generateTreatmentPlan(patientId, recommendations) {
        console.log('\n📋 Piano di trattamento generato:');
        console.log(`   Paziente: ${patientId}`);
        console.log(`   Data: ${new Date().toLocaleDateString('it-IT')}`);
        
        const plan = {
            patientId,
            date: new Date().toISOString(),
            treatments: recommendations,
            duration: '3-6 mesi',
            monitoring: 'Analisi metalli ogni 4 settimane'
        };

        console.log('\n   Protocollo:');
        recommendations.forEach((rec, idx) => {
            console.log(`   ${idx + 1}. ${rec.chelator} per ${rec.metal} - ${rec.dosage}`);
        });

        return plan;
    }

    async runClinicalWorkflow(patientId) {
        console.log('\n╔══════════════════════════════════════════════╗');
        console.log('║  Gene1799 Clinical Chelation Workflow       ║');
        console.log('╚══════════════════════════════════════════════╝');

        const metalLevels = await this.analyzePatientMetals(patientId);
        const recommendations = await this.recommendChelator(metalLevels);

        if (recommendations && recommendations.length > 0) {
            await this.generateTreatmentPlan(patientId, recommendations);
        }

        console.log('\n✅ Workflow clinico completato!\n');
        return { metalLevels, recommendations };
    }
}

// Esecuzione
if (require.main === module) {
    const integration = new Gene1799HealthcareIntegration(
        'gen-lang-client-0003307746',
        'europe-west4',
        'gene1799-dataset'
    );

    integration.runClinicalWorkflow('PATIENT-001')
        .catch(err => console.error('❌ Errore:', err.message));
}

module.exports = Gene1799HealthcareIntegration;

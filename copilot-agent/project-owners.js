const ProjectOwners = [
    {
        nome: "Marco Antonio Saverio Mazzitelli",
        ruolo: "Co-Proprietario (50%)",
        contatto: "+39 339 763 0479"
    },
    {
        nome: "Fabio Amedeo Lo Presti",
        ruolo: "Co-Proprietario (50%)", 
        contatto: "+39 377 339 9932"
    }
];

console.log("👥 Proprietari Gene1799ArtCorporatione:");
ProjectOwners.forEach(owner => {
    console.log(`  • ${owner.nome}`);
    console.log(`    Ruolo: ${owner.ruolo}`);
    console.log(`    Contatto: ${owner.contatto}\n`);
});

module.exports = ProjectOwners;

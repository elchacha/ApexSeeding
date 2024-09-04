public with sharing class DataFactory implements Queueable {

    /*
    pour nettoyer l'org : new DataFactory(null).deleteAll();
    
    pour créer la première fois les csvDataFactory : System.enqueueJob(new DataFactory(DataFactory.Operation.DATAFACTORYCREATION));


    pour creer les données sans utiliser les csvDataFactory (plus lent) : 
        new DataFactory(DataFactory.Operation.SEEDING).execute(null);
    pour creer les données en utilisant les csvDataFactory : (plus rapide)
        new DataFactory(DataFactory.Operation.DATAFACTORYREAD).execute(null);

    */

    public enum Operation {SEEDING, DATAFACTORYCREATION, DATAFACTORYREAD}

    private final String datafactoryCsvPatten='DataFactory1';

    private Operation operationType;

    public DataFactory(Operation operationType){
        this.operationType=operationType;   
    }

    public void deleteAll(){
        Database.delete([SELECT Id FROM SelParamVariente__c],false);
        Database.delete([SELECT Id FROM SelCandidature__c],false);
        Database.delete([SELECT Id FROM SelRecrutement__c],false);
        Database.delete([SELECT Id FROM SelDocumentSousEtapeTypeSelection__c],false);
        Database.delete([SELECT Id FROM SelStructureEpreuveTypeSelection__c],false);
        Database.delete([SELECT Id FROM SelSousEtapeTypeSelection__c],false);
        Database.delete([SELECT Id FROM SelEtapeTypeSelection__c],false);
        Database.delete([SELECT Id FROM SelVersionStructure__c],false);
        Database.delete([SELECT Id FROM Account],false);
        Database.delete([SELECT Id FROM SelRefEtapeStatut__c],false);
        Database.delete([SELECT Id FROM SelRefLieu__c],false);
        Database.delete([SELECT Id FROM SelRefStatut__c],false);
        Database.delete([SELECT Id FROM SelRefSpecialite__c],false);
        Database.delete([SELECT Id FROM Sel_Ref_Situation_Conjugale__c],false);
        Database.delete([SELECT Id FROM SelRefEcole__c],false);
        Database.delete([SELECT Id FROM SelRefGrade__c],false);
        Database.delete([SELECT Id FROM SelRefOrigineArme__c],false);
        Database.delete([SELECT Id FROM SelRefCIR__c],false);
        Database.delete([SELECT Id FROM Sel_Ref_CSC__c],false);
        Database.delete([SELECT Id FROM SelRefCompetence__c],false);
        Database.delete([SELECT Id FROM SelRefLangueEtrangere__c],false);
        Database.delete([SELECT Id FROM SelRefFiliereRaep__c],false);
        Database.delete([SELECT Id FROM SelRefFiliere__c],false);
        Database.delete([SELECT Id FROM Sel_Ref_Option__c],false);
        Database.delete([SELECT Id FROM Sel_Ref_Villes__c],false);
        Database.delete([SELECT Id FROM Sel_Departements__c],false);
        Database.delete([SELECT Id FROM SelRefDocument__c],false);
        Database.delete([SELECT Id FROM SelRefSousEtape__c],false);
        Database.delete([SELECT Id FROM SelRefCategorieDocument__c],false);
        Database.delete([SELECT Id FROM Sel_Ref_Niveau__c],false);
        Database.delete([SELECT Id FROM SelRefTypeSelection__c],false);
        Database.delete([SELECT Id FROM SelRefCorps__c],false);
    }

    public void execute(QueueableContext context) {

        DateTime startTime = DateTime.now();
        if(operationType==Operation.SEEDING){
            LoadData.loadCsvSeedingMode('Sel');
        }else if(operationType==Operation.DATAFACTORYCREATION){
            LoadData.loadCsvDataFactoryMode('Sel',datafactoryCsvPatten);
        }else if(operationType==Operation.DATAFACTORYREAD){
            LoadData.loadTestRecords(datafactoryCsvPatten);
        }
        LoadData.loadData(SelRefCorps__c.sObjectType,'SelRefCorps','Name');
        LoadData.loadData(SelRefTypeSelection__c.sObjectType,'SelRefTypeSelection','lib_technique__c');
        LoadData.loadData(Sel_Ref_Niveau__c.sObjectType,'Sel_Ref_Niveau','Name');
        LoadData.loadData(SelRefEtape__c.sObjectType,'SelRefEtape','Name');
        LoadData.loadData(SelRefCategorieDocument__c.sObjectType,'SelRefCategorieDocument','Code__c');
        LoadData.loadData(SelRefSousEtape__c.sObjectType,'SelRefSousEtape','Code__c');
        LoadData.loadData(SelRefDocument__c.sObjectType,'SelRefDocument','Name');
        LoadData.loadData(Sel_Departements__c.sObjectType,'Sel_Departements','name');
        LoadData.loadData(Sel_Ref_Villes__c.sObjectType,'SelRefVilles92','name');
        LoadData.loadData(Sel_Ref_Option__c.sObjectType,'Sel_Ref_Option','name');
        LoadData.loadData(SelRefFiliere__c.sObjectType,'SelRefFiliere','name');
        LoadData.loadData(SelRefFiliereRaep__c.sObjectType,'SelRefFiliereRaep','name');
        LoadData.loadData(SelRefLangueEtrangere__c.sObjectType,'SelRefLangueEtrangere','name');
        LoadData.loadData(SelRefCompetence__c.sObjectType,'SelRefCompetence','name');
        LoadData.loadData(Sel_Ref_CSC__c.sObjectType,'SelRefCsc','name');
        LoadData.loadData(SelRefCIR__c.sObjectType,'SelRefCir','name');
        LoadData.loadData(SelRefOrigineArme__c.sObjectType,'SelRefOrigineArme','name');
        LoadData.loadData(SelRefGrade__c.sObjectType,'SelRefGrade','code__c');
        LoadData.loadData(SelRefEcole__c.sObjectType,'SelRefEcole','name');
        LoadData.loadData(Sel_Ref_Situation_Conjugale__c.sObjectType,'SelRefSituationConjugale','name');
        LoadData.loadData(SelRefSpecialite__c.sObjectType,'SelRefSpecialite','name');
        LoadData.loadData(SelRefLieu__c.sObjectType,'SelRefLieu','name');
        LoadData.loadData(SelRefStatut__c.sObjectType,'SelRefStatut','code__c');
        LoadData.loadData(SelRefEtapeStatut__c.sObjectType,'SelRefEtapeStatut','code__c');
        LoadData.loadData(Account.sObjectType,'SelAccount','NID__c');
        LoadData.loadData(SelVersionStructure__c.sObjectType,'SelVersionStructure','ExternalId__c');
        LoadData.loadData(SelEtapeTypeSelection__c.sObjectType,'SelEtapeTypeSelection','Name');
        LoadData.loadData(SelSousEtapeTypeSelection__c.sObjectType,'SelSousEtapeTypeSelection','ExternalId__c');
        LoadData.loadData(SelStructureEpreuveTypeSelection__c.sObjectType,'SelStructureEpreuveTypeSelection','Name');
        LoadData.loadData(SelDocumentSousEtapeTypeSelection__c.sObjectType,'SelDocumentSousEtapeTypeSelection','numCounter__c');
        LoadData.loadData(SelRecrutement__c.sObjectType,'SelRecrutement','ExternalId__c');
        LoadData.loadData(SelCandidature__c.sObjectType,'SelCandidature','ExternalId__c');
        LoadData.loadData(SelParamVariente__c.sObjectType,'SelParamVariente','ExternalId__c');

        system.debug(' Executed in '+(DateTime.now().gettime()-startTime.gettime())+' ms');
   }
}
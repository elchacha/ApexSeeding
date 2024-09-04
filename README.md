3 options :

To create serialized and optimized files :
System.enqueueJob(new DataFactory(DataFactory.Operation.DATAFACTORYCREATION));

To simply seed from csv :
new DataFactory(DataFactory.Operation.SEEDING).execute(null);

To run in a datafactory :
new DataFactory(DataFactory.Operation.DATAFACTORYREAD).execute(null);


I need to set as variable the criteria to load the needed static resources. Currently it is hard code with ('Sel')
 LoadData.loadCsvSeedingMode('Sel'); 
 LoadData.loadCsvDataFactoryMode('Sel',datafactoryCsvPatten);

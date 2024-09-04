public with sharing class LoadData {
    /*
        LoadData.loadCsv(new List<String>{'SelRefCorps','SelRefTypeSelection'});
        LoadData.loadData(SelRefCorps__c.Sobjecttype,'SelRefCorps','Code__c');
        LoadData.loadData(SelRefTypeSelection__c.Sobjecttype,'SelRefTypeSelection');


        ajoute :
        détection des objets ayant besoin d'une ref parent non encore inséré --> limit dml opération
        détection des objets pouvant etre updaté avec une ref parent non obligatoire
    */

    // all possible fields of the object bind by developerName
    static Map<String, Schema.SObjectField> fieldMap;
    // list of fields Name to insert
    static list<String> fieldToInsert;
    // current objectType process as a String value
    static String sOType;
    // OPTIONAL : external field Id chosen to bind the record to its Id
    static String currentFieldExternalId;
    // map of the Id of objects already created (bind by defaut on the id but can supercharge with an "external field Id" like bulk upsert in cli)
    static Map<String,String> idsCreatedMapping =new Map<String,String>();
    static Map<String,List<Sobject>> objectsCreatedMapping =new Map<String,List<Sobject>>();

    // list of records to insert when ready (either one by one or by group if no references are required)
    static List<Sobject> records;
    static List<TestRecord> recordsLookups;
    // all static resources needed loaded once (to consume only 1 SOQL query)
    static Map<String,String> csvMaps;
    static Map<String,List<TestRecord>> lookupHelperMaps;
    // temporare line, not to be kept
    static List<LookupHelper> currentLineRecordsLookups;
    // list of value collected to be part of the key in idsCreatedMapping
    static List<String> idNames;

    private static boolean isLoadData=false;

    private static Set<String> notEditable = new Set<String>();
    static{
        notEditable.add('Account.Name');
    }

    static private boolean modeCreation=false;
    static private boolean modeInsertion=false;
    static private boolean modeTest=false;

    static private String strDataFactoryPattern;


    public static void loadCsvSeedingMode(List<String> names){
        loadCsv(names,true,false);
    }
    public static void loadCsvDataFactoryMode(List<String> names){
        loadCsv(names,false,true);
    }

    // only one call to load all csv files neeeded
    private static void loadCsv(List<String> names,boolean pModeInsertion,boolean pModeCreation){
        modeCreation=pModeCreation;
        modeInsertion=pModeInsertion;
        csvMaps =new Map<String,String>();
        String query ='SELECT Id,Name, Body FROM StaticResource WHERE Name =:names';
        for(StaticResource csv : Database.query(query)){
            csvMaps.put(csv.Name,csv.Body.toString());
        }
    }


    public static void loadCsvSeedingMode(String pattern){
        loadCsv(pattern,true,false);
    }
    public static void loadCsvDataFactoryMode(String pattern,String patternCsvDatafactory){
        // patternCsvDatafactory should only contains number and letter. No special caracters
        strDataFactoryPattern=patternCsvDatafactory;
        loadCsv(pattern,false,true);
    }

    // only one call to load all csv files neeeded
    public static void loadCsv(String pattern,boolean pModeInsertion,boolean pModeCreation){
        System.debug('memoire avant : '+Limits.getHeapSize());
        modeCreation=pModeCreation;
        modeInsertion=pModeInsertion;
        csvMaps =new Map<String,String>();
        String query ='SELECT Id,Name, Body FROM StaticResource WHERE Name like \'%'+pattern+'%\'';
        for(StaticResource csv : Database.query(query)){
            csvMaps.put(csv.Name,csv.Body.toString());
        }
        System.debug('memoire apres : '+Limits.getHeapSize());
    }


    public static void loadTestRecords(String pattern){
        System.debug('memoire avant : '+Limits.getHeapSize());
        modeCreation=false;
        modeInsertion=true;
        modeTest=true;
        lookupHelperMaps = new Map<String,List<TestRecord>>();
        String query ='SELECT Id,Name, Body FROM StaticResource WHERE Name like \''+pattern+'%\'';
        for(StaticResource csv : Database.query(query)){
            lookupHelperMaps.put(csv.Name.replaceAll('_c','__c').replace(pattern, ''),(List<TestRecord>)JSON.deserializeStrict(csv.Body.toString(),List<TestRecord>.class));
        }
        System.debug('memoire apres : '+Limits.getHeapSize());
    }

    public static void loadData(sObjectType type,String csvStaticResource){
        loadData(type,csvStaticResource,null);
    }

    public static List<Sobject> loadData(sObjectType type,String csvStaticResource,String fieldExternalId){
        isLoadData=true;
        idNames=new List<String>();
        records = new List<Sobject>();
        recordsLookups = new List<TestRecord>();

        system.debug('processing csv : '+csvStaticResource);
        // describe fields for object
        sOType = String.valueOf(type);
        fieldMap = Schema.describeSObjects(new String[]{sOType})[0].fields.getMap();
        currentFieldExternalId=fieldExternalId;

        loadRecordTypes(type);

        if(!modeTest){
            // read the csv file
            List<List<string>> filelines = CsvUtil.parse(csvMaps.get(csvStaticResource));
            // reduce heapSize
            csvMaps.remove(csvStaticResource);
            fieldToInsert=filelines[0];

            for(integer i=1;i<filelines.size();i++){
                currentLineRecordsLookups = new List<LookupHelper>();
                Sobject curentRecord = processLine(filelines[i],i);
                records.add(curentRecord);
                recordsLookups.add(new TestRecord(curentRecord,currentLineRecordsLookups));
            }
        }else{
            recordsLookups= lookupHelperMaps.get(sOType);
            for(TestRecord aTestRecord : recordsLookups){
                Sobject curentRecord = aTestRecord.record;
                for(LookupHelper lookup : aTestRecord.lookups){
                    curentRecord.put(lookup.fieldName,getLookupId(lookup.parentType,lookup.parentFieldName,lookup.value));
                }
                records.add(curentRecord);
            }
        }

        if(modeInsertion){
            doInsertion();
        }
        if(modeCreation){
            createStaticRecords();
        }

        return records;
    }

    private static void loadRecordTypes(sObjectType type){
        Map<String, Schema.RecordTypeInfo> mapRecordTypeByDevName = type.getDescribe().getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> mapRecordTypeByName = type.getDescribe().getRecordTypeInfosByName();
        for(String devName : mapRecordTypeByDevName.keyset()){
            idsCreatedMapping.put(sOType+'.'+devName,mapRecordTypeByDevName.get(devName).getRecordTypeId());
        }
        for(String name : mapRecordTypeByName.keyset()){
            idsCreatedMapping.put(sOType+'.'+name,mapRecordTypeByName.get(name).getRecordTypeId());
        }
    }

    private static void recalculateColumnsFieldsName(list<String> columnsWithPotentialExternalId){
        fieldToInsert = new list<String>();
        for(String fieldName : columnsWithPotentialExternalId){
            if(fieldName.contains('.')){
                fieldName=fieldName.split(('\\.'))[1];
            }
            fieldToInsert.add(fieldName);
        }
    }

    private static Sobject processLine(List<string> fields,Integer linePosition){
        Integer pos =0;
        Sobject obj =Schema.getGlobalDescribe().get(sOType).newSObject();
        for(String value : fields){
            try {
                processField(fieldToInsert[pos],value.trim(),obj);
            } catch (Exception e) {
                throw getException(e,fieldToInsert[pos],linePosition);
            }
            pos++;
        }
        return obj;
    }

    private static void processField(String fieldName,String value,Sobject obj){
        String parentFieldName=fieldName;
        if(fieldName.contains('.')){
            parentFieldName=fieldName.split(('\\.'))[1];
            fieldName=fieldName.split(('\\.'))[0];
            if(fieldName.endsWith('__r')){
                fieldName=fieldName.replace('__r', '__c');
            }else{
                fieldName=fieldName+'Id';
            }
        }

        String fieldType = fieldMap.get(fieldName).getDescribe().getType().toString();

        if(fieldName=='id'){
            idNames.add(value);
        }else if(!notEditable.contains(sOType+'.'+fieldName)){
            if(fieldName==currentFieldExternalId){
                idNames.add(value);
            }
            if(value=='null'||value==''){
                obj.put(fieldName,null);
            }else{
                switch on fieldType {
                    when 'DATETIME' {
                        obj.put(fieldName,DateTime.valueOf(value.replace('T',' ')));
                    }	
                    when 'DATE' {
                        try {
                            obj.put(fieldName,Date.valueOf(value));
                        } catch (TypeException te) {
                            obj.put(fieldName,DateTime.valueOf(value.replace('T',' ')).date());
                        }
                    }	
                    when 'BOOLEAN' {		// when block 2
                        obj.put(fieldName,Boolean.valueOf(value));
                    }
                    when 'DOUBLE','DECIMAL','PERCENT','CURRENCY','INTEGER' {		// when block 2
                        try {
                            obj.put(fieldName,Double.valueOf(value));
                        } catch (Exception ex) {
                            obj.put(fieldName,0);
                        }
                    }
                    when 'REFERENCE' {		// when block 3
                        String refToObject = String.valueOf(fieldMap.get(fieldName).getDescribe().getReferenceTo()[0]);
                        if(fieldName=='RecordTypeId'){
                            parentFieldName=sOType;
                        }
                        if(modeInsertion){
                            obj.put(fieldName,getLookupId(refToObject,parentFieldName,value));
                        }else if(modeCreation){
                            currentLineRecordsLookups.add(new LookupHelper(refToObject,parentFieldName,value,fieldName));
                        }
                    }
                    when else {		  // default block, optional
                        if(value=='null'){
                            value=null;
                        }
                        obj.put(fieldName,value);
                    }
                }
    

            }

        }

    }

    private static String getLookupId(String parentType,String parentFieldName,String value){
        if(value=='null'||value==''){
            return null;
        }

        boolean isRT=false;
        value=value.replaceAll('"', '');
        if(parentType=='RecordType'){
            isRT=true;
            if(idsCreatedMapping.containsKey(parentFieldName+'.'+value)){
                return idsCreatedMapping.get(parentFieldName+'.'+value);
            }else{
                System.debug('could not find a RT name '+value+' for Sobject '+parentFieldName);
            }
        }else{
            for(Sobject parentRecord : objectsCreatedMapping.get(parentType)){
                if(String.valueOf(parentRecord.get(parentFieldName))==value){
                    return parentRecord.Id;
                }
            }
        }

        if(value!='null'&&value!=''&&!isRT){
            system.debug('ERROR > fake id : '+value+' is not mapped yet for object '+parentType +' and fieldName = '+parentFieldName +' while importing records for : '+sOType);
        }
        return null;
    }

    public static void doInsertion(){
        try {
            String str = JSON.serialize(recordsLookups); 
            insert records;

            // should always be the case 
            if(!objectsCreatedMapping.containsKey(sOType)){
                objectsCreatedMapping.put(sOType,new List<SObject>());
            }

            for(Sobject obj : records){
                objectsCreatedMapping.get(sOType).add(obj);
            }
        } catch (Exception e) {
            system.debug('Error with object : '+sOType);
            system.debug('Msg : '+e.getMessage());
            system.debug('Stack Trace : '+e.getStackTraceString());
            throw getException(e);
        }
    }


    public static void createStaticRecords(){
        try {

            String str = JSON.serialize(recordsLookups); 
            DateTime startTime = DateTime.now();
            List<TestRecord> c = (List<TestRecord>)JSON.deserializeStrict(str,List<TestRecord>.class);
            system.debug(' deserialized in ms : '+(DateTime.now().gettime()-startTime.gettime()));
            createStaticResources(str,sOType);
            system.debug(c);
        } catch (Exception e) {
            system.debug('Error with object : '+sOType);
            system.debug('Msg : '+e.getMessage());
            system.debug('Stack Trace : '+e.getStackTraceString());
            throw getException(e);
        }
    }

    public static boolean isLoadingData(){
        return isLoadData;
    }


    private static GenericException getException(Exception e){
        return getException(e, null,-1);
    }
    
    private static GenericException getException(Exception e,String fieldName,Integer csvLine){
        String msg = e.getMessage()+'\n';
        msg+='ERROR HAPPENED WHILE LOADING OBJECT : '+sOType;
        if(fieldName!=null){
            msg+=' for field name '+fieldName+' at line '+csvLine;
        }
        msg+='\n';

        system.debug('full msg  : '+msg);

        return new GenericException(msg);
    }


    private class LookupHelper{
        public String parentType;
        public String parentFieldName;
        public String value;
        public String fieldName;

        public LookupHelper(){}

        public LookupHelper(String parentType,String parentFieldName,String value,String fieldName){
            this.parentType=parentType;
            this.parentFieldName=parentFieldName;
            this.value=value;
            this.fieldName=fieldName;
        }
    }

    private class TestRecord{
        Sobject record;
        List<LookupHelper> lookups;

        public TestRecord(){}
        public TestRecord(Sobject record,List<LookupHelper> lookups){
            this.record=record;
            this.lookups=lookups;
        }
    }


    public static void createStaticResources(String serialized,String name){

        name=strDataFactoryPattern+name.replace('__','_');
        List<StaticResource> resources = [SELECT Id from StaticResource where Name =:name];
        if(resources.size()>0){
            ToolingApiUtil.deleteObject('StaticResource',resources[0].Id);
        }
        Map<String,Object> externalString = new Map<String,Object>();
        externalString.put('Body',EncodingUtil.base64Encode(Blob.valueOf(serialized)));
        externalString.put('CacheControl','Private');
        externalString.put('ContentType','text');
        externalString.put('Name',name);
        externalString.put('Description','serialisé pour etre utilisé par la datafactory');
        ToolingApiUtil.createObject('StaticResource',externalString);
    }

}
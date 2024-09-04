public with sharing class DataFactorySerializedResources implements Queueable,Database.AllowsCallouts {

    String name;
    String serialized;

    public DataFactorySerializedResources(String name,String serialized){
        this.name='DataFactory_'+name.replace('__','_');
        this.serialized=serialized;
    }

    public void execute(QueueableContext context) {
        List<StaticResource> resources = [SELECT Id from StaticResource where Name =:name];
        if(resources.size()>0){
            ToolingApiUtil.deleteObject('StaticResource',resources[0].Id);
        }

        System.debug(EncodingUtil.base64Encode(Blob.valueOf(serialized)));
        System.debug('Name>'+name);

        Map<String,Object> externalString = new Map<String,Object>();
        externalString.put('Body',EncodingUtil.base64Encode(Blob.valueOf(serialized)));
//        externalString.put('Body','test');
        externalString.put('CacheControl','Private');
        externalString.put('ContentType','text');
        externalString.put('Name',name);
        externalString.put('Description','serialisé pour etre utilisé par la datafactory');
        ToolingApiUtil.createObject('StaticResource',externalString);
    }
}
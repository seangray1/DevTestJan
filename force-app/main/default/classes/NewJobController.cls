public with sharing class NewJobController {
    @AuraEnabled
    public static List<Account_Roles__c> GetAccountRoles(String PropertyId) {
        Id PropertyIDFinal;
        system.debug('Property is ' + PropertyID);
        JSONWrapper PropertyIDs = (JSONWrapper)JSON.deserialize(PropertyId, JSONWrapper.class);
        // for(Id ca : PropertyIDs.PropertyID){
        // PropertyIDFinal = ca; }
        system.debug('PropertyID is ' + PropertyID);
        List<Account_Roles__c> a = [Select Name FROM Account_Roles__c Where Property_ID__c =: PropertyIDs.PropertyID];
        system.debug('Account roles are ' + a);
        return a;
    }
    public class JSONWrapper{
        public List<Id> PropertyId {get;set;}
    }
    @AuraEnabled
    public static List<Property__c> GetProperties(String searchKey) {
        
        system.debug('Property is ' + searchKey);
        //JSONWrapper PropertyIDs = (JSONWrapper)JSON.deserialize(PropertyId, JSONWrapper.class);
        // for(Id ca : PropertyIDs.PropertyID){
        // PropertyIDFinal = ca; }
        String searchLikeKey = '%' + searchKey + '%';
        List<Property__c> props = [Select Name FROM Property__c Where Name Like : searchKey];
        system.debug('Properties are ' + props);
        return props;
    }
    
}
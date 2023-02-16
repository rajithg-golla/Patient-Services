({
    setStatus : function(component) {
        const problemRecord = component.get("v.problemRecord");
        const problemItemComponent = component.find("problemItem");
        $A.util.addClass(problemItemComponent, "slds-is-" + problemRecord.PJN_CarePlan_Path_Status__c);
    },
    hoverProblem : function(component) {
        const hoverComponent = component.find("hoverProblem");
        $A.util.toggleClass(hoverComponent, "slds-hide");
    },
    selectThisProblem : function(component) {
        const problemItemComponent = component.find("problemItem");
        $A.util.addClass(problemItemComponent, "slds-is-active");
    },
    deselectThisProblem : function(component) {
        const problemItemComponent = component.find("problemItem");
        $A.util.removeClass(problemItemComponent, "slds-is-active");
    }
});
({
    onInit : function(component, event, helper) {
        helper.init(component);
    },
    onHandleProblemSelection: function(component, event, helper) {
        helper.handleProblemSelection(component, event);
    },
    onSelectChange : function(component, event, helper) {
        helper.setVariants(component);
    },
    onHoverPlay : function(component, event, helper) {
        helper.hoverPlay(component);
    },
    onHoverSkip : function(component, event, helper) {
        helper.hoverSkip(component);
    },
    onHoverDelete : function(component, event, helper) {
        helper.hoverDelete(component);
    },
    onHoverOut : function(component, event, helper) {
        helper.setVariants(component);
    },
    onPlayProblem : function(component, event, helper) {
        helper.playProblem(component);
    },
    onSkipProblem : function(component, event, helper) {
        helper.skipProblem(component);
    },
    onDeleteProblem : function(component, event, helper) {
        helper.deleteProblem(component);
    }
});
global class RelayMessageActionRequest {
    @InvocableVariable(required=false description='')
    public List<RelayMessagingRequest> batchRequest;

    @InvocableVariable(required=false description='')
    public RelayMessagingRequest singleRequest;

    @InvocableVariable(label='Dynamic input_ variable names' required=false)
    public List<String> dynamicInputFieldNames;

    @InvocableVariable(label='Trigger ID' required=false)
    public String triggerId;

    @InvocableVariable(label='Send via future' required=true)
    public Boolean useFuture = true;
}
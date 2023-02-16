trigger RelayTaskTrigger on Task (after insert) {
  Relay_Network__mdt[] settings = [SELECT RelayDisableTaskEventing__c FROM Relay_Network__mdt];  
  Boolean disableTaskEventing = false;
  if (settings.size() > 0 ) {
      disableTaskEventing = settings[0].RelayDisableTaskEventing__c;

  }

  if (!disableTaskEventing) {
    for (Task t: Trigger.new) {
      if (t.Subject != null ) {
        if (t.Subject.startsWithIgnoreCase('call')) {
          EventBus.publish(new RelayReminder__e(WhoId__c=t.WhoId, WhatId__c=t.WhatId));
        }
      }
    }
  }
}
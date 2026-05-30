import org.moqui.entity.EntityValue

//validation
if(!partyId) {
    ec.message.addError("Party ID is a required Field")
    return
}

EntityValue person = ec.entity.find("com.moqui.party.Person").condition("partyId", partyId).one()

//If Person not found
if(person == null) {
    ec.message.addError("Person record does not exist for partyId: " + partyId)
    return
}

// Delete the Person record in the database
person.delete()

String responseMsg = "Person deleted successfully from database"
ec.message.addMessage(responseMsg)
context.responseString=responseMsg

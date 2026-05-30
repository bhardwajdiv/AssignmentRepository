import org.moqui.entity.EntityValue

// Validate that partyId, firstName, and lastName are provided
if (!partyId) {
    ec.message.addError("partyId is missing")
}
if (!firstName) {
    ec.message.addError("firstName is missing")
}
if (!lastName) {
    ec.message.addError("lastName is missing")
}

// Return an error if any required parameter is missing
if (ec.message.hasError()) {
    return
}

// Verify that a Party record exists for the given partyId
EntityValue party = ec.entity.find("com.moqui.party.Party").condition("partyId", partyId).one()
if (party == null) {
    ec.message.addError("Party record does not exist for partyId: " + partyId)
    return
}

// Ensure the Person is created only if the Party exists
EntityValue newPerson = ec.entity.makeValue("com.moqui.party.Person")


newPerson.setFields(context, true, null, null)

newPerson.create()


String responseMsg = "Person ${firstName} ${lastName} created successfully!"
ec.message.addMessage(responseMsg)
context.responseString = responseMsg

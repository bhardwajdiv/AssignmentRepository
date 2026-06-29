<#--
    findCustomer.ftl — Step 8
    Customer search screen with filter form, results table, pagination,
    and four modal dialogs:
      1. Create Customer
      2. Update Customer (pre-filled from row Edit button)
      3. Create Relationship
      4. Update Relationship
-->

<#-- ════════════════════ SEARCH FILTER FORM ════════════════════ -->
<div class="screenlet">
    <div class="screenlet-title-bar">
        <ul><li class="h3">${uiLabelMap.CustomerManagementFindCustomer}</li></ul>
        <br class="clear"/>
    </div>
    <div class="screenlet-body">
        <form method="get" action="<@ofbizUrl>FindCustomer</@ofbizUrl>" name="findCustomerForm">
            <table class="basic-table" cellspacing="0">
                <tr>
                    <td class="label">${uiLabelMap.CustomerManagementPartyId}</td>
                    <td><input type="text" name="partyId" value="${parameters.partyId!}" class="inputBox"/></td>
                    <td class="label">${uiLabelMap.CustomerManagementFirstName}</td>
                    <td><input type="text" name="firstName" value="${parameters.firstName!}" class="inputBox"/></td>
                </tr>
                <tr>
                    <td class="label">${uiLabelMap.CustomerManagementLastName}</td>
                    <td><input type="text" name="lastName" value="${parameters.lastName!}" class="inputBox"/></td>
                    <td class="label">${uiLabelMap.CustomerManagementEmail}</td>
                    <td><input type="text" name="emailAddress" value="${parameters.emailAddress!}" class="inputBox"/></td>
                </tr>
                <tr>
                    <td class="label">${uiLabelMap.CustomerManagementPhone}</td>
                    <td><input type="text" name="contactNumber" value="${parameters.contactNumber!}" class="inputBox"/></td>
                    <td class="label">${uiLabelMap.CustomerManagementAddress}</td>
                    <td><input type="text" name="address" value="${parameters.address!}" class="inputBox"/></td>
                </tr>
                <tr>
                    <td colspan="4" style="text-align:center; padding:8px;">
                        <input type="submit" value="Search" class="smallSubmit"/>
                        &nbsp;
                        <input type="button" value="Clear" class="smallSubmit"
                            onclick="window.location='<@ofbizUrl>FindCustomer</@ofbizUrl>'"/>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

<#-- ════════════════════ ACTION TOOLBAR ════════════════════ -->
<div class="screenlet">
    <div class="screenlet-body" style="padding:8px;">
        <button class="smallSubmit" onclick="showModal('createCustomerModal')">+ Add Customer</button>
        &nbsp;
        <button class="smallSubmit" onclick="showModal('createRelationshipModal')">Link Parties</button>
        &nbsp;
        <button class="smallSubmit" onclick="showModal('updateRelationshipModal')">Update Relationship</button>
    </div>
</div>

<#-- ════════════════════ RESULTS TABLE ════════════════════ -->
<div class="screenlet">
    <div class="screenlet-title-bar">
        <ul><li class="h3">Results &mdash; ${totalCount!0} customer(s) found</li></ul>
        <br class="clear"/>
    </div>
    <div class="screenlet-body">
        <#if customerList?has_content>
            <table class="basic-table hover-bar" cellspacing="0">
                <thead>
                    <tr class="header-row-2">
                        <th>Party ID</th>
                        <th>First Name</th>
                        <th>Last Name</th>
                        <th>Email Address</th>
                        <th>Phone</th>
                        <th>Address</th>
                        <th>City</th>
                        <th>Postal Code</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <#list customerList as cust>
                        <tr>
                            <td>${cust.partyId!}</td>
                            <td>${cust.firstName!}</td>
                            <td>${cust.lastName!}</td>
                            <td>${cust.emailAddress!}</td>
                            <td>${cust.contactNumber!}</td>
                            <td>${cust.address1!}</td>
                            <td>${cust.city!}</td>
                            <td>${cust.postalCode!}</td>
                            <td>
                                <button class="smallSubmit"
                                    onclick="openUpdateModal(
                                        '${(cust.emailAddress!)?js_string}',
                                        '${(cust.contactNumber!)?js_string}',
                                        '${(cust.address1!)?js_string}',
                                        '${(cust.city!)?js_string}',
                                        '${(cust.postalCode!)?js_string}',
                                        '${(cust.countryGeoId!)?js_string}')">
                                    Edit
                                </button>
                            </td>
                        </tr>
                    </#list>
                </tbody>
            </table>

            <#-- ── Pagination ── -->
            <#assign qs>partyId=${parameters.partyId!}&firstName=${parameters.firstName!}&lastName=${parameters.lastName!}&emailAddress=${parameters.emailAddress!}&contactNumber=${parameters.contactNumber!}&address=${parameters.address!}&pageSize=${pageSize!10}</#assign>
            <div style="text-align:center; margin-top:12px;">
                <#if (pageIndex!0) gt 0>
                    <a href="<@ofbizUrl>FindCustomer?${qs}&pageIndex=${(pageIndex!0) - 1}</@ofbizUrl>">&laquo; Prev</a>
                    &nbsp;
                </#if>
                <#if (totalPages!1) gt 0>
                    <#list 0..((totalPages!1) - 1) as p>
                        <#if p == (pageIndex!0)>
                            <strong>[${p + 1}]</strong>
                        <#else>
                            <a href="<@ofbizUrl>FindCustomer?${qs}&pageIndex=${p}</@ofbizUrl>">${p + 1}</a>
                        </#if>
                        &nbsp;
                    </#list>
                </#if>
                <#if (pageIndex!0) lt ((totalPages!1) - 1)>
                    &nbsp;
                    <a href="<@ofbizUrl>FindCustomer?${qs}&pageIndex=${(pageIndex!0) + 1}</@ofbizUrl>">Next &raquo;</a>
                </#if>
            </div>
        <#else>
            <p style="padding:10px;">No customers match the search criteria.</p>
        </#if>
    </div>
</div>

<#-- ════════════════════ MODAL OVERLAY ════════════════════ -->
<div id="cmOverlay" onclick="hideAllModals()"
    style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;
           background:rgba(0,0,0,0.5);z-index:900;"></div>

<#-- ── Modal 1: Create Customer ── -->
<div id="createCustomerModal" class="cm-modal" style="display:none;">
    <h3>Create Customer</h3>
    <form method="post" action="<@ofbizUrl>createCustomer</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Email Address *</td>
                <td><input type="email" name="emailAddress" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">First Name *</td>
                <td><input type="text" name="firstName" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Last Name *</td>
                <td><input type="text" name="lastName" required class="inputBox"/></td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center;padding-top:8px;">
                    <input type="submit" value="Create" class="smallSubmit"/>
                    &nbsp;
                    <button type="button" class="smallSubmit" onclick="hideAllModals()">Cancel</button>
                </td>
            </tr>
        </table>
    </form>
</div>

<#-- ── Modal 2: Update Customer (pre-filled by Edit button) ── -->
<div id="updateCustomerModal" class="cm-modal" style="display:none;">
    <h3>Update Customer</h3>
    <form method="post" action="<@ofbizUrl>updateCustomer</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Email Address *</td>
                <td><input type="email" id="ucEmail" name="emailAddress" required class="inputBox" readonly/></td>
            </tr>
            <tr>
                <td class="label">Phone Number</td>
                <td><input type="text" id="ucPhone" name="contactNumber" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Address</td>
                <td><input type="text" id="ucAddress" name="address1" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">City</td>
                <td><input type="text" id="ucCity" name="city" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Postal Code</td>
                <td><input type="text" id="ucPostal" name="postalCode" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Country Code</td>
                <td><input type="text" id="ucCountry" name="countryGeoId" class="inputBox" placeholder="e.g. USA"/></td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center;padding-top:8px;">
                    <input type="submit" value="Update" class="smallSubmit"/>
                    &nbsp;
                    <button type="button" class="smallSubmit" onclick="hideAllModals()">Cancel</button>
                </td>
            </tr>
        </table>
    </form>
</div>

<#-- ── Modal 3: Create Party Relationship (Step 6a) ── -->
<div id="createRelationshipModal" class="cm-modal" style="display:none;">
    <h3>Create Party Relationship</h3>
    <form method="post" action="<@ofbizUrl>createCustomerRelationship</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Party ID From *</td>
                <td><input type="text" name="partyIdFrom" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Party ID To *</td>
                <td><input type="text" name="partyIdTo" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Relationship Type *</td>
                <td>
                    <select name="partyRelationshipTypeId" required class="inputBox">
                        <option value="">-- Select Type --</option>
                        <#if partyRelationshipTypes?has_content>
                            <#list partyRelationshipTypes as rt>
                                <option value="${rt.partyRelationshipTypeId}">
                                    ${rt.description!rt.partyRelationshipTypeId}
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
            </tr>
            <tr>
                <td class="label">Role From</td>
                <td><input type="text" name="roleTypeIdFrom" class="inputBox" placeholder="Leave blank for _NA_"/></td>
            </tr>
            <tr>
                <td class="label">Role To</td>
                <td><input type="text" name="roleTypeIdTo" class="inputBox" placeholder="Leave blank for _NA_"/></td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center;padding-top:8px;">
                    <input type="submit" value="Create Relationship" class="smallSubmit"/>
                    &nbsp;
                    <button type="button" class="smallSubmit" onclick="hideAllModals()">Cancel</button>
                </td>
            </tr>
        </table>
    </form>
</div>

<#-- ── Modal 4: Update Party Relationship (Step 6b) ── -->
<div id="updateRelationshipModal" class="cm-modal" style="display:none;">
    <h3>Update Party Relationship</h3>
    <form method="post" action="<@ofbizUrl>updateCustomerRelationship</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Party ID From *</td>
                <td><input type="text" name="partyIdFrom" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Party ID To *</td>
                <td><input type="text" name="partyIdTo" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Relationship Type *</td>
                <td>
                    <select name="partyRelationshipTypeId" required class="inputBox">
                        <option value="">-- Select Type --</option>
                        <#if partyRelationshipTypes?has_content>
                            <#list partyRelationshipTypes as rt>
                                <option value="${rt.partyRelationshipTypeId}">
                                    ${rt.description!rt.partyRelationshipTypeId}
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
            </tr>
            <tr>
                <td class="label">Role From</td>
                <td><input type="text" name="roleTypeIdFrom" class="inputBox" placeholder="Leave blank for _NA_"/></td>
            </tr>
            <tr>
                <td class="label">Role To</td>
                <td><input type="text" name="roleTypeIdTo" class="inputBox" placeholder="Leave blank for _NA_"/></td>
            </tr>
            <tr>
                <td class="label">New Status</td>
                <td><input type="text" name="statusId" class="inputBox" placeholder="e.g. PARTY_ENABLED"/></td>
            </tr>
            <tr>
                <td class="label">Through Date</td>
                <td>
                    <input type="text" name="thruDate" class="inputBox"
                        placeholder="yyyy-MM-dd HH:mm:ss.S"/>
                </td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center;padding-top:8px;">
                    <input type="submit" value="Update Relationship" class="smallSubmit"/>
                    &nbsp;
                    <button type="button" class="smallSubmit" onclick="hideAllModals()">Cancel</button>
                </td>
            </tr>
        </table>
    </form>
</div>

<#-- ════════════════════ MODAL STYLES & JS ════════════════════ -->
<style>
.cm-modal {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: #ffffff;
    border: 1px solid #aaa;
    padding: 20px 24px;
    z-index: 1000;
    min-width: 440px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.3);
}
.cm-modal h3 {
    margin-top: 0;
    border-bottom: 1px solid #ddd;
    padding-bottom: 8px;
}
</style>

<script type="text/javascript">
function showModal(id) {
    document.getElementById('cmOverlay').style.display = 'block';
    document.getElementById(id).style.display = 'block';
}
function hideAllModals() {
    ['createCustomerModal','updateCustomerModal','createRelationshipModal','updateRelationshipModal']
        .forEach(function(id) { document.getElementById(id).style.display = 'none'; });
    document.getElementById('cmOverlay').style.display = 'none';
}
function openUpdateModal(email, phone, address, city, postal, country) {
    document.getElementById('ucEmail').value   = email;
    document.getElementById('ucPhone').value   = phone;
    document.getElementById('ucAddress').value = address;
    document.getElementById('ucCity').value    = city;
    document.getElementById('ucPostal').value  = postal;
    document.getElementById('ucCountry').value = country;
    showModal('updateCustomerModal');
}
</script>

<#--
    findProduct.ftl — Step 8
    Product search screen with filter form, results table, pagination,
    and four modal dialogs for create / update / assoc / update-variant actions.
    Rendered by ProductManagementScreens.xml#FindProduct via platform-specific.
-->

<#-- ════════════════════ SEARCH FILTER FORM ════════════════════ -->
<div class="screenlet">
    <div class="screenlet-title-bar">
        <ul><li class="h3">${uiLabelMap.ProductManagementFindProduct}</li></ul>
        <br class="clear"/>
    </div>
    <div class="screenlet-body">
        <form method="get" action="<@ofbizUrl>FindProduct</@ofbizUrl>" name="findProductForm">
            <table class="basic-table" cellspacing="0">
                <tr>
                    <td class="label">${uiLabelMap.ProductManagementProductId}</td>
                    <td><input type="text" name="productId" value="${parameters.productId!}" class="inputBox"/></td>
                    <td class="label">${uiLabelMap.ProductManagementProductName}</td>
                    <td><input type="text" name="productName" value="${parameters.productName!}" class="inputBox"/></td>
                </tr>
                <tr>
                    <td class="label">Min Price</td>
                    <td><input type="text" name="priceMin" value="${parameters.priceMin!}" class="inputBox" placeholder="0.00"/></td>
                    <td class="label">Max Price</td>
                    <td><input type="text" name="priceMax" value="${parameters.priceMax!}" class="inputBox" placeholder="0.00"/></td>
                </tr>
                <tr>
                    <td class="label">${uiLabelMap.ProductManagementCategory}</td>
                    <td>
                        <select name="productCategoryId" class="inputBox">
                            <option value="">-- All Categories --</option>
                            <#if productCategoryList?has_content>
                                <#list productCategoryList as cat>
                                    <option value="${cat.productCategoryId}"
                                        <#if (parameters.productCategoryId!) == cat.productCategoryId>selected</#if>>
                                        ${cat.categoryName!cat.productCategoryId}
                                    </option>
                                </#list>
                            </#if>
                        </select>
                    </td>
                    <td class="label">${uiLabelMap.ProductManagementFeatureType}</td>
                    <td>
                        <select name="productFeatureTypeId" class="inputBox">
                            <option value="">-- All Feature Types --</option>
                            <#if productFeatureTypeList?has_content>
                                <#list productFeatureTypeList as ft>
                                    <option value="${ft.productFeatureTypeId}"
                                        <#if (parameters.productFeatureTypeId!) == ft.productFeatureTypeId>selected</#if>>
                                        ${ft.description!ft.productFeatureTypeId}
                                    </option>
                                </#list>
                            </#if>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td colspan="4" style="text-align:center; padding:8px;">
                        <input type="submit" value="Search" class="smallSubmit"/>
                        &nbsp;
                        <input type="button" value="Clear" class="smallSubmit"
                            onclick="window.location='<@ofbizUrl>FindProduct</@ofbizUrl>'"/>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

<#-- ════════════════════ ACTION TOOLBAR ════════════════════ -->
<div class="screenlet">
    <div class="screenlet-body" style="padding:8px;">
        <button class="smallSubmit" onclick="showModal('createProductModal')">+ Add Product</button>
        &nbsp;
        <button class="smallSubmit" onclick="showModal('assocVariantModal')">Link Variant</button>
        &nbsp;
        <button class="smallSubmit" onclick="showModal('updateVariantModal')">Update Variant Link</button>
    </div>
</div>

<#-- ════════════════════ RESULTS TABLE ════════════════════ -->
<div class="screenlet">
    <div class="screenlet-title-bar">
        <ul><li class="h3">Results &mdash; ${totalCount!0} product(s) found</li></ul>
        <br class="clear"/>
    </div>
    <div class="screenlet-body">
        <#if productList?has_content>
            <table class="basic-table hover-bar" cellspacing="0">
                <thead>
                    <tr class="header-row-2">
                        <th>Product ID</th>
                        <th>Name</th>
                        <th>Type</th>
                        <th>List Price</th>
                        <th>Category</th>
                        <th>Feature</th>
                        <th>Virtual</th>
                        <th>Variant</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <#list productList as product>
                        <tr>
                            <td>${product.productId!}</td>
                            <td>${product.productName!}</td>
                            <td>${product.productTypeId!}</td>
                            <td><#if product.price??>${product.price?string("0.00")}</#if></td>
                            <td>${product.categoryName!}</td>
                            <td>${product.featureDescription!}</td>
                            <td><#if (product.isVirtual!) == "Y"><strong>Yes</strong></#if></td>
                            <td><#if (product.isVariant!) == "Y"><strong>Yes</strong></#if></td>
                            <td>
                                <button class="smallSubmit"
                                    onclick="openUpdateModal(
                                        '${product.productId!}',
                                        '${(product.productName!)?js_string}',
                                        '${product.price!}',
                                        '${(product.featureDescription!)?js_string}')">
                                    Edit
                                </button>
                            </td>
                        </tr>
                    </#list>
                </tbody>
            </table>

            <#-- ── Pagination ── -->
            <#assign qs>productId=${parameters.productId!}&productName=${parameters.productName!}&priceMin=${parameters.priceMin!}&priceMax=${parameters.priceMax!}&productCategoryId=${parameters.productCategoryId!}&productFeatureTypeId=${parameters.productFeatureTypeId!}&pageSize=${pageSize!10}</#assign>
            <div style="text-align:center; margin-top:12px;">
                <#if (pageIndex!0) gt 0>
                    <a href="<@ofbizUrl>FindProduct?${qs}&pageIndex=${(pageIndex!0) - 1}</@ofbizUrl>">&laquo; Prev</a>
                    &nbsp;
                </#if>
                <#if (totalPages!1) gt 0>
                    <#list 0..((totalPages!1) - 1) as p>
                        <#if p == (pageIndex!0)>
                            <strong>[${p + 1}]</strong>
                        <#else>
                            <a href="<@ofbizUrl>FindProduct?${qs}&pageIndex=${p}</@ofbizUrl>">${p + 1}</a>
                        </#if>
                        &nbsp;
                    </#list>
                </#if>
                <#if (pageIndex!0) lt ((totalPages!1) - 1)>
                    &nbsp;
                    <a href="<@ofbizUrl>FindProduct?${qs}&pageIndex=${(pageIndex!0) + 1}</@ofbizUrl>">Next &raquo;</a>
                </#if>
            </div>
        <#else>
            <p style="padding:10px;">No products match the search criteria.</p>
        </#if>
    </div>
</div>

<#-- ════════════════════ MODAL OVERLAY ════════════════════ -->
<div id="pmOverlay" onclick="hideAllModals()"
    style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;
           background:rgba(0,0,0,0.5);z-index:900;"></div>

<#-- ── Create Product Modal ── -->
<div id="createProductModal" class="pm-modal" style="display:none;">
    <h3>Create Product</h3>
    <form method="post" action="<@ofbizUrl>createProduct</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Product Name *</td>
                <td><input type="text" name="productName" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Category *</td>
                <td>
                    <select name="productCategoryId" required class="inputBox">
                        <option value="">-- Select --</option>
                        <#if productCategoryList?has_content>
                            <#list productCategoryList as cat>
                                <option value="${cat.productCategoryId}">
                                    ${cat.categoryName!cat.productCategoryId}
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
            </tr>
            <tr>
                <td class="label">Price *</td>
                <td><input type="number" step="0.01" name="price" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Description</td>
                <td><input type="text" name="description" class="inputBox"/></td>
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

<#-- ── Update Product Modal ── -->
<div id="updateProductModal" class="pm-modal" style="display:none;">
    <h3>Update Product</h3>
    <form method="post" action="<@ofbizUrl>updateProduct</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Product ID *</td>
                <td><input type="text" id="upProductId" name="productId" required class="inputBox" readonly/></td>
            </tr>
            <tr>
                <td class="label">Product Name</td>
                <td><input type="text" id="upProductName" name="productName" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Price</td>
                <td><input type="number" step="0.01" id="upPrice" name="price" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Description</td>
                <td><input type="text" id="upDescription" name="description" class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Add Feature</td>
                <td>
                    <select name="productFeatureId" class="inputBox">
                        <option value="">-- None --</option>
                        <#if allProductFeatures?has_content>
                            <#list allProductFeatures as feat>
                                <option value="${feat.productFeatureId}">
                                    ${feat.description!feat.productFeatureId}
                                    (${feat.productFeatureTypeId!})
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
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

<#-- ── Associate Variant Modal (Step 6a) ── -->
<div id="assocVariantModal" class="pm-modal" style="display:none;">
    <h3>Associate Product as Variant</h3>
    <form method="post" action="<@ofbizUrl>assocProductToVirtual</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Variant Product ID *</td>
                <td><input type="text" name="productId" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Virtual Product *</td>
                <td>
                    <select name="virtualProductId" required class="inputBox">
                        <option value="">-- Select Virtual --</option>
                        <#if virtualProducts?has_content>
                            <#list virtualProducts as vp>
                                <option value="${vp.productId}">
                                    ${vp.internalName!vp.productId}
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center;padding-top:8px;">
                    <input type="submit" value="Associate" class="smallSubmit"/>
                    &nbsp;
                    <button type="button" class="smallSubmit" onclick="hideAllModals()">Cancel</button>
                </td>
            </tr>
        </table>
    </form>
</div>

<#-- ── Update Variant Relationship Modal (Step 6b) ── -->
<div id="updateVariantModal" class="pm-modal" style="display:none;">
    <h3>Update Variant Relationship</h3>
    <form method="post" action="<@ofbizUrl>updateProductVariant</@ofbizUrl>">
        <table class="basic-table" cellspacing="4">
            <tr>
                <td class="label">Variant Product ID *</td>
                <td><input type="text" name="productId" required class="inputBox"/></td>
            </tr>
            <tr>
                <td class="label">Current Virtual Product *</td>
                <td>
                    <select name="virtualProductId" required class="inputBox">
                        <option value="">-- Select Virtual --</option>
                        <#if virtualProducts?has_content>
                            <#list virtualProducts as vp>
                                <option value="${vp.productId}">
                                    ${vp.internalName!vp.productId}
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
            </tr>
            <tr>
                <td class="label">Through Date</td>
                <td>
                    <input type="text" name="thruDate" class="inputBox"
                        placeholder="yyyy-MM-dd HH:mm:ss.S"/>
                </td>
            </tr>
            <tr>
                <td class="label">New Virtual Product</td>
                <td>
                    <select name="newVirtualProductId" class="inputBox">
                        <option value="">-- No Change --</option>
                        <#if virtualProducts?has_content>
                            <#list virtualProducts as vp>
                                <option value="${vp.productId}">
                                    ${vp.internalName!vp.productId}
                                </option>
                            </#list>
                        </#if>
                    </select>
                </td>
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

<#-- ════════════════════ MODAL STYLES & JS ════════════════════ -->
<style>
.pm-modal {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: #ffffff;
    border: 1px solid #aaa;
    padding: 20px 24px;
    z-index: 1000;
    min-width: 420px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.3);
}
.pm-modal h3 {
    margin-top: 0;
    border-bottom: 1px solid #ddd;
    padding-bottom: 8px;
}
</style>

<script type="text/javascript">
function showModal(id) {
    document.getElementById('pmOverlay').style.display = 'block';
    document.getElementById(id).style.display = 'block';
}
function hideAllModals() {
    ['createProductModal','updateProductModal','assocVariantModal','updateVariantModal']
        .forEach(function(id) { document.getElementById(id).style.display = 'none'; });
    document.getElementById('pmOverlay').style.display = 'none';
}
function openUpdateModal(productId, productName, price, description) {
    document.getElementById('upProductId').value   = productId;
    document.getElementById('upProductName').value = productName;
    document.getElementById('upPrice').value       = price;
    document.getElementById('upDescription').value = description;
    showModal('updateProductModal');
}
</script>

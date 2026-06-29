<#--
    findProduct.ftl — Step 8
    ========================
    FreeMarker template for the Find Product view screen.

    Context variables injected by findProduct.xml actions:
        productList         List<EntityValue>  — search results (deduplicated)
        categoryList        List<EntityValue>  — all ProductCategory records
        featureTypeList     List<EntityValue>  — all ProductFeatureType records
        allFeatures         List<EntityValue>  — all ProductFeature records
        allProducts         List<EntityValue>  — virtual products only (for assoc forms)

    URL search parameters preserved for filters and pagination:
        productId, productName, priceMin, priceMax,
        productFeatureTypeId, productCategoryId, pageIndex, pageSize
-->
<#assign pageIndex  = (pageIndex!0)?number>
<#assign pageSize   = (pageSize!10)?number>

<div class="container-fluid" style="padding: 20px;">

    <!-- ═══════════════════════════════════════════════════════════ -->
    <!--  PAGE HEADER                                               -->
    <!-- ═══════════════════════════════════════════════════════════ -->
    <div class="row">
        <div class="col-sm-12">
            <h2 style="margin-top:0;">
                <span class="glyphicon glyphicon-search"></span>
                Find Product
            </h2>
            <hr/>
        </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════ -->
    <!--  SEARCH FILTER FORM                                        -->
    <!-- ═══════════════════════════════════════════════════════════ -->
    <div class="panel panel-default">
        <div class="panel-heading">
            <h3 class="panel-title">Search Filters</h3>
        </div>
        <div class="panel-body">
            <form method="get" action="" class="form-horizontal">
                <div class="row">

                    <!-- Product ID -->
                    <div class="col-sm-2">
                        <div class="form-group">
                            <label class="control-label">Product ID</label>
                            <input type="text" name="productId" class="form-control"
                                   value="${productId!''}" placeholder="Exact match"/>
                        </div>
                    </div>

                    <!-- Product Name (partial, case-insensitive) -->
                    <div class="col-sm-3">
                        <div class="form-group">
                            <label class="control-label">Product Name</label>
                            <input type="text" name="productName" class="form-control"
                                   value="${productName!''}" placeholder="Partial match…"/>
                        </div>
                    </div>

                    <!-- Price range -->
                    <div class="col-sm-2">
                        <div class="form-group">
                            <label class="control-label">Min Price</label>
                            <div class="input-group">
                                <span class="input-group-addon">$</span>
                                <input type="number" name="priceMin" class="form-control"
                                       value="${priceMin!''}" step="0.01" placeholder="0.00"/>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-2">
                        <div class="form-group">
                            <label class="control-label">Max Price</label>
                            <div class="input-group">
                                <span class="input-group-addon">$</span>
                                <input type="number" name="priceMax" class="form-control"
                                       value="${priceMax!''}" step="0.01"/>
                            </div>
                        </div>
                    </div>

                    <!-- Category -->
                    <div class="col-sm-2">
                        <div class="form-group">
                            <label class="control-label">Category</label>
                            <select name="productCategoryId" class="form-control">
                                <option value="">All Categories</option>
                                <#if categoryList??>
                                    <#list categoryList as cat>
                                        <option value="${cat.productCategoryId}"
                                            <#if (productCategoryId!'') == cat.productCategoryId?string>selected</#if>>
                                            ${cat.categoryName}
                                        </option>
                                    </#list>
                                </#if>
                            </select>
                        </div>
                    </div>

                    <!-- Feature Type -->
                    <div class="col-sm-2">
                        <div class="form-group">
                            <label class="control-label">Feature Type</label>
                            <select name="productFeatureTypeId" class="form-control">
                                <option value="">Any Feature</option>
                                <#if featureTypeList??>
                                    <#list featureTypeList as ft>
                                        <option value="${ft.productFeatureTypeId}"
                                            <#if (productFeatureTypeId!'') == ft.productFeatureTypeId?string>selected</#if>>
                                            ${ft.description}
                                        </option>
                                    </#list>
                                </#if>
                            </select>
                        </div>
                    </div>

                </div><!-- /.row -->

                <!-- Hidden pagination reset -->
                <input type="hidden" name="pageIndex" value="0"/>
                <input type="hidden" name="pageSize"  value="${pageSize}"/>

                <div class="row">
                    <div class="col-sm-12">
                        <button type="submit" class="btn btn-primary">
                            <span class="glyphicon glyphicon-search"></span> Search
                        </button>
                        <a href="?" class="btn btn-default">
                            <span class="glyphicon glyphicon-remove"></span> Clear
                        </a>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════ -->
    <!--  ACTION TOOLBAR (event trigger buttons)                    -->
    <!-- ═══════════════════════════════════════════════════════════ -->
    <div class="row" style="margin-bottom: 12px;">
        <div class="col-sm-12">
            <button type="button" class="btn btn-success"
                    data-toggle="modal" data-target="#createProductModal">
                <span class="glyphicon glyphicon-plus"></span> Create Product
            </button>
            &nbsp;
            <button type="button" class="btn btn-primary"
                    data-toggle="modal" data-target="#updateProductModal">
                <span class="glyphicon glyphicon-pencil"></span> Update Product
            </button>
            &nbsp;
            <button type="button" class="btn btn-info"
                    data-toggle="modal" data-target="#assocVariantModal">
                <span class="glyphicon glyphicon-link"></span> Assign Variant to Virtual
            </button>
            &nbsp;
            <button type="button" class="btn btn-warning"
                    data-toggle="modal" data-target="#updateVariantModal">
                <span class="glyphicon glyphicon-transfer"></span> Update Variant Assoc
            </button>
        </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════ -->
    <!--  SEARCH RESULTS TABLE WITH PAGINATION                      -->
    <!-- ═══════════════════════════════════════════════════════════ -->
    <div class="panel panel-default">
        <div class="panel-heading">
            <h3 class="panel-title">
                Search Results
                <#if productList?? && productList?size gt 0>
                    <span class="badge" style="margin-left:6px;">${productList?size}</span>
                </#if>
            </h3>
        </div>
        <div class="panel-body">

        <#if productList?? && productList?size gt 0>

            <#-- ── Pagination maths ─────────────────────────────────────── -->
            <#assign totalCount = productList?size>
            <#assign totalPages = ((totalCount - 1) / pageSize)?floor + 1>
            <#assign startIdx   = pageIndex * pageSize>
            <#assign endIdx     = [startIdx + pageSize, totalCount]?min>

            <#-- Build base query string (without pageIndex) for pagination links -->
            <#assign qBase = "productId=" + (productId!'') +
                             "&productName=" + (productName!'') +
                             "&priceMin=" + (priceMin!'') +
                             "&priceMax=" + (priceMax!'') +
                             "&productCategoryId=" + (productCategoryId!'') +
                             "&productFeatureTypeId=" + (productFeatureTypeId!'') +
                             "&pageSize=" + pageSize>

            <p class="text-muted small">
                Showing ${startIdx + 1}–${endIdx} of ${totalCount} product(s).
            </p>

            <div class="table-responsive">
                <table class="table table-striped table-hover table-condensed">
                    <thead>
                        <tr>
                            <th>Product ID</th>
                            <th>Product Name</th>
                            <th>Type</th>
                            <th>List Price</th>
                            <th>Category</th>
                            <th>Feature</th>
                            <th>Virtual</th>
                            <th>Variant</th>
                            <th>Quick Edit</th>
                        </tr>
                    </thead>
                    <tbody>
                        <#list productList[startIdx..endIdx - 1] as prod>
                        <tr>
                            <td><strong>${prod.productId!''}</strong></td>
                            <td>${prod.productName!''}</td>
                            <td>
                                <span class="label label-default">${prod.productTypeEnumId!''}</span>
                            </td>
                            <td>
                                <#if prod.price??>
                                    $${prod.price?string("0.00")}
                                <#else>
                                    <span class="text-muted">—</span>
                                </#if>
                            </td>
                            <td>${prod.categoryName!''}</td>
                            <td>
                                <#if prod.featureDescription?? && prod.featureDescription != "">
                                    <span class="label label-info">${prod.productFeatureTypeId!''}</span>
                                    ${prod.featureDescription}
                                <#else>
                                    <span class="text-muted">—</span>
                                </#if>
                            </td>
                            <td>
                                <#if (prod.isVirtual!'N') == 'Y'>
                                    <span class="label label-warning">Virtual</span>
                                <#else>—</#if>
                            </td>
                            <td>
                                <#if (prod.isVariant!'N') == 'Y'>
                                    <span class="label label-success">Variant</span>
                                <#else>—</#if>
                            </td>
                            <td>
                                <!-- Pre-fill the Update modal via data- attributes -->
                                <button type="button" class="btn btn-xs btn-primary js-edit-btn"
                                        data-toggle="modal" data-target="#updateProductModal"
                                        data-productid="${prod.productId!''}"
                                        data-productname="${prod.productName!''}"
                                        title="Edit product">
                                    <span class="glyphicon glyphicon-pencil"></span>
                                </button>
                            </td>
                        </tr>
                        </#list>
                    </tbody>
                </table>
            </div>

            <#-- ── Pagination controls ──────────────────────────────────── -->
            <#if totalPages gt 1>
            <nav aria-label="Product search pagination">
                <ul class="pagination pagination-sm">

                    <#-- Previous -->
                    <li class="${(pageIndex <= 0)?string('disabled', '')}">
                        <a href="?${qBase}&pageIndex=${(pageIndex - 1)?max(0)}" aria-label="Previous">
                            <span aria-hidden="true">&laquo;</span>
                        </a>
                    </li>

                    <#-- Page numbers -->
                    <#list 0..totalPages - 1 as p>
                    <li class="${(p == pageIndex)?string('active', '')}">
                        <a href="?${qBase}&pageIndex=${p}">${p + 1}</a>
                    </li>
                    </#list>

                    <#-- Next -->
                    <li class="${(pageIndex >= totalPages - 1)?string('disabled', '')}">
                        <a href="?${qBase}&pageIndex=${(pageIndex + 1)?min(totalPages - 1)}" aria-label="Next">
                            <span aria-hidden="true">&raquo;</span>
                        </a>
                    </li>

                </ul>
            </nav>
            </#if>

        <#elseif productId?? || productName?? || priceMin?? || priceMax?? ||
                  productCategoryId?? || productFeatureTypeId??>
            <div class="alert alert-info">
                <span class="glyphicon glyphicon-info-sign"></span>
                No products found matching the given criteria.
            </div>
        <#else>
            <div class="alert alert-info">
                <span class="glyphicon glyphicon-info-sign"></span>
                Enter one or more search criteria above and click <strong>Search</strong>.
            </div>
        </#if>

        </div>
    </div>

</div><!-- /.container-fluid -->


<!-- ═══════════════════════════════════════════════════════════════════ -->
<!--  MODAL 1 — Create Product (event: createProduct)                  -->
<!-- ═══════════════════════════════════════════════════════════════════ -->
<div class="modal fade" id="createProductModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title">
                    <span class="glyphicon glyphicon-plus-sign"></span> Create New Product
                </h4>
            </div>
            <form method="post" action="createProduct">
                <div class="modal-body">

                    <div class="form-group">
                        <label>Product Name <span class="text-danger">*</span></label>
                        <input type="text" name="productName" class="form-control"
                               placeholder="Must be unique" required/>
                    </div>

                    <div class="form-group">
                        <label>Category <span class="text-danger">*</span></label>
                        <select name="productCategoryId" class="form-control" required>
                            <option value="">— Select Category —</option>
                            <#if categoryList??>
                                <#list categoryList as cat>
                                    <option value="${cat.productCategoryId}">${cat.categoryName}</option>
                                </#list>
                            </#if>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>List Price <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-addon">$</span>
                            <input type="number" name="price" class="form-control"
                                   step="0.01" min="0" placeholder="0.00" required/>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" class="form-control" rows="2"
                                  placeholder="Optional description"></textarea>
                    </div>

                    <div class="row">
                        <div class="col-sm-6">
                            <div class="form-group">
                                <label>Is Virtual?</label>
                                <select name="isVirtual" class="form-control">
                                    <option value="N">No</option>
                                    <option value="Y">Yes</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="form-group">
                                <label>Is Variant?</label>
                                <select name="isVariant" class="form-control">
                                    <option value="N">No</option>
                                    <option value="Y">Yes</option>
                                </select>
                            </div>
                        </div>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-success">
                        <span class="glyphicon glyphicon-ok"></span> Create Product
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<!-- ═══════════════════════════════════════════════════════════════════ -->
<!--  MODAL 2 — Update Product (event: updateProduct)                  -->
<!-- ═══════════════════════════════════════════════════════════════════ -->
<div class="modal fade" id="updateProductModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title">
                    <span class="glyphicon glyphicon-pencil"></span> Update Product
                </h4>
            </div>
            <form method="post" action="updateProduct">
                <div class="modal-body">

                    <div class="form-group">
                        <label>Product ID <span class="text-danger">*</span></label>
                        <input type="text" name="productId" id="upd-productId"
                               class="form-control" required placeholder="e.g. PROD10001"/>
                        <p class="help-block">Fill from the table Edit button, or type manually.</p>
                    </div>

                    <div class="form-group">
                        <label>New Name <small class="text-muted">(leave blank to keep current)</small></label>
                        <input type="text" name="productName" id="upd-productName" class="form-control"/>
                    </div>

                    <div class="form-group">
                        <label>New Description</label>
                        <textarea name="description" class="form-control" rows="2"></textarea>
                    </div>

                    <hr/>
                    <h5>Price Update</h5>

                    <div class="row">
                        <div class="col-sm-6">
                            <div class="form-group">
                                <label>New Price</label>
                                <div class="input-group">
                                    <span class="input-group-addon">$</span>
                                    <input type="number" name="price" class="form-control"
                                           step="0.01" min="0" placeholder="leave blank = no change"/>
                                </div>
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="form-group">
                                <label>Price Type</label>
                                <select name="priceTypeEnumId" class="form-control">
                                    <option value="LIST_PRICE">List Price</option>
                                    <option value="PROMOTIONAL_PRICE">Promotional</option>
                                    <option value="WHOLESALE_PRICE">Wholesale</option>
                                    <option value="COST_PRICE">Cost</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <hr/>
                    <h5>Apply Feature <small class="text-muted">(optional)</small></h5>

                    <div class="row">
                        <div class="col-sm-8">
                            <div class="form-group">
                                <label>Feature</label>
                                <select name="productFeatureId" class="form-control">
                                    <option value="">— None —</option>
                                    <#if allFeatures??>
                                        <#list allFeatures as feat>
                                            <option value="${feat.productFeatureId}">
                                                ${feat.productFeatureTypeId} — ${feat.description}
                                            </option>
                                        </#list>
                                    </#if>
                                </select>
                            </div>
                        </div>
                        <div class="col-sm-4">
                            <div class="form-group">
                                <label>Application Type</label>
                                <select name="productFeatureApplTypeEnumId" class="form-control">
                                    <option value="STANDARD_FEATURE">Standard</option>
                                    <option value="SELECTABLE_FEATURE">Selectable</option>
                                </select>
                            </div>
                        </div>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="glyphicon glyphicon-ok"></span> Update Product
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<!-- ═══════════════════════════════════════════════════════════════════ -->
<!--  MODAL 3 — Assign Variant to Virtual (event: assocProductToVirtual) -->
<!-- ═══════════════════════════════════════════════════════════════════ -->
<div class="modal fade" id="assocVariantModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title">
                    <span class="glyphicon glyphicon-link"></span> Assign Variant to Virtual Product
                </h4>
            </div>
            <form method="post" action="assocProductToVirtual">
                <div class="modal-body">

                    <p class="text-muted">
                        Creates a <strong>VARIANT</strong> association:
                        <em>Virtual → Variant</em>.
                    </p>

                    <div class="form-group">
                        <label>Virtual Product <span class="text-danger">*</span></label>
                        <select name="virtualProductId" class="form-control" required>
                            <option value="">— Select Virtual Product —</option>
                            <#if allProducts??>
                                <#list allProducts as vp>
                                    <option value="${vp.productId}">
                                        ${vp.productId} — ${vp.productName!''}
                                    </option>
                                </#list>
                            </#if>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Variant Product ID <span class="text-danger">*</span></label>
                        <input type="text" name="productId" class="form-control"
                               placeholder="e.g. PROD10001" required/>
                        <p class="help-block">Enter the ID of the product to mark as a variant.</p>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-info">
                        <span class="glyphicon glyphicon-ok"></span> Create Association
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<!-- ═══════════════════════════════════════════════════════════════════ -->
<!--  MODAL 4 — Update Variant Association (event: updateProductVariant) -->
<!-- ═══════════════════════════════════════════════════════════════════ -->
<div class="modal fade" id="updateVariantModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title">
                    <span class="glyphicon glyphicon-transfer"></span> Update Variant Association
                </h4>
            </div>
            <form method="post" action="updateProductVariant">
                <div class="modal-body">

                    <p class="text-muted">
                        Expire or reassign an existing <strong>VARIANT</strong> association.
                    </p>

                    <div class="form-group">
                        <label>Current Virtual Product <span class="text-danger">*</span></label>
                        <select name="virtualProductId" class="form-control" required>
                            <option value="">— Select Virtual Product —</option>
                            <#if allProducts??>
                                <#list allProducts as vp>
                                    <option value="${vp.productId}">
                                        ${vp.productId} — ${vp.productName!''}
                                    </option>
                                </#list>
                            </#if>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Variant Product ID <span class="text-danger">*</span></label>
                        <input type="text" name="productId" class="form-control"
                               placeholder="e.g. PROD10001" required/>
                    </div>

                    <hr/>

                    <div class="form-group">
                        <label>Expire Association (Thru Date)</label>
                        <input type="datetime-local" name="thruDate" class="form-control"/>
                        <p class="help-block">Leave blank if not expiring the current association.</p>
                    </div>

                    <div class="form-group">
                        <label>Transfer to New Virtual Product</label>
                        <select name="newVirtualProductId" class="form-control">
                            <option value="">— No transfer —</option>
                            <#if allProducts??>
                                <#list allProducts as vp>
                                    <option value="${vp.productId}">
                                        ${vp.productId} — ${vp.productName!''}
                                    </option>
                                </#list>
                            </#if>
                        </select>
                        <p class="help-block">
                            Selecting a new virtual product will expire the current association
                            and create a new one under the selected virtual.
                        </p>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-warning">
                        <span class="glyphicon glyphicon-ok"></span> Update Association
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


<!-- ═══════════════════════════════════════════════════════════════════ -->
<!--  JAVASCRIPT — pre-fill Update Product modal from table row        -->
<!-- ═══════════════════════════════════════════════════════════════════ -->
<script>
(function () {
    'use strict';
    /* When the Update Product modal opens via an Edit button in the table,
       copy the data- attributes into the modal's input fields.           */
    var modal = document.getElementById('updateProductModal');
    if (modal) {
        modal.addEventListener('show.bs.modal', function (event) {
            var btn = event.relatedTarget;
            if (!btn || !btn.dataset.productid) return;
            document.getElementById('upd-productId').value    = btn.dataset.productid   || '';
            document.getElementById('upd-productName').value  = btn.dataset.productname || '';
        });
    }
}());
</script>

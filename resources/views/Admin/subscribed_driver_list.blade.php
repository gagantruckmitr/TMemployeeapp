@include('Admin.layouts.header')
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<style>
.checked {
    color: orange;
}
</style>
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                    <div class="page-sub-header">
                        <h3 class="page-title">Driver</h3>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-sm-12">

                <div class="card card-table comman-shadow">
                    <div class="card-body">
                        <div class="page-header">
                            <div class="row align-items-center">
                                <div class="col">
                                    <h3 class="page-title">Subscribed Driver List</h3>
                                </div>
                                <br>

                                <div class="col-auto d-flex align-items-center gap-2">

                                    <form action="{{ route('subscribed-drivers.export') }}" method="GET"
                                        style="display:inline-block;">
                                        <input type="hidden" name="added_by" value="{{ request()->input('added_by') }}">
                                        <input type="hidden" name="state_name"
                                            value="{{ request()->input('state_name') }}">
                                        <input type="hidden" name="status" value="{{ request()->input('status') }}">
                                        <input type="hidden" name="from_date"
                                            value="{{ request()->input('from_date') }}">
                                        <input type="hidden" name="to_date" value="{{ request()->input('to_date') }}">
                                        <button class="btn btn-success btn-sm" type="submit">Export to Excel <i
                                                class="fas fa-file-export"></i></button>
                                    </form> 

                                    {{-- Filter Button --}}
                                    <button
                                        style="background-color: #1a6dba !important; border:0 !important; outline:0 !important"
                                        type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal"
                                        data-bs-target="#filterModal">
                                        <i class="fas fa-filter me-1"></i> Filter
                                    </button>

                                    {{-- Show Clear Filter Button only if filters are applied --}}

                                    @if(request()->filled('added_by') || request()->filled('state_name') ||
                                    request()->filled('from_date') || request()->filled('to_date') ||
                                    request()->filled('status') || request()->filled('rating') ||
                                    request()->filled('tier') || request()->filled('payment_status'))
                                    <a href="{{ url('admin/subscribed-drivers') }}"
                                        class="btn btn-outline-secondary btn-sm">
                                        Clear Filter
                                    </a>
                                    @endif

                                </div>
                            </div>
                        </div>
                        <div class="col"> Show Entries
                            <form method="GET" action="{{ url('admin/subscribed-drivers') }}">
                                <select name="per_page" onchange="this.form.submit()">
                                    <option value="10" {{ request('per_page') == 10 ? 'selected' : '' }}>10</option>
                                    <option value="25" {{ request('per_page') == 25 ? 'selected' : '' }}>25</option>
                                    <option value="50" {{ request('per_page') == 50 ? 'selected' : '' }}>50</option>
                                    <option value="100" {{ request('per_page') == 100 ? 'selected' : '' }}>100</option>
                                </select>
                            </form>
                        </div>
                        <form method="GET" action="{{ url('admin/subscribed-drivers') }}">
                            <div class="row mb-3">
                                <div class="col-md-4">
                                    <input type="text" name="global_search" value="{{ request('global_search') }}"
                                        class="form-control" placeholder="Search drivers...">
                                </div>
                                <div class="col-md-2">
                                    <button type="submit" class="btn btn-primary">Search</button>
                                </div>
                            </div>
                        </form>
                        <div class="table-responsive">
                            <table
                                class="table border-0 star-student table-hover table-center mb-0 datatable table-striped"
                                id="dfUsageTable">
                                <thead class="student-thread">
                                    <tr>
                                        <th>TM ID</th>
                                        <th>Driver Added By</th>
                                        <th>Image</th>
                                        <th>Name</th>
                                        <th>State</th>
                                        <th>Rating</th>
                                        <th>Ranking</th>
                                        <th>Job Status</th>
                                        <th>Mobile</th>
                                        <th>Email</th>
                                        <!-- <th>Subscribed</th> -->
                                        <th>Registration Date</th>
                                        <th>Subscription Date</th>
                                        <th>Status</th>
                                        <th class="text-end">Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @if(isset($driver))
                                    @foreach($driver as $key=>$list)

                                    <?php $res = get_rating_and_ranking_by_all_module($list->id);

// FILTER MATCHING LOGIC STARTS HERE
if ((request('rating') && $res['rating'] != request('rating')) ||
    (request('tier') && $res['tier'] != request('tier'))) {
    continue;
}
// FILTER LOGIC ENDS HERE
?>
                                    <tr>
                                        <td><a href="/admin/driver-applied-job/{{$list->id}}">{{$list->unique_id}}</a>
                                        </td>
                                        <td><?php echo $list->sub_id ? 'Added By Transporter' : 'Self'; ?></td>
                                        <td>
                                            <h2 class="table-avatar">
                                                <a href="#" class="avatar avatar-sm me-2">
                                                    <img class="avatar-img rounded-circle"
                                                        src="{{ $list->images != '' ? url('/public/'.$list->images) : url('/public/noimg.png') }}"
                                                        alt="User Image" loading="lazy"
                                                        onerror="this.onerror=null;this.src='https://truckmitr.com/public/noimg.png';">
                                                </a>
                                            </h2>
                                        </td>
                                        <td>{{$list->name}}</td>
                                        <td>{{ $list->state_name ?? 'N/A' }}</td>
                                        <td>
                                            <?php
                                        for ($i = 0; $i < $res['rating']; $i++) {
                                            echo '<span class="fa fa-star checked"></span>';
                                        }
                                        for ($i = $res['rating']; $i < 5; $i++) {
                                            echo '<span class="fa fa-star"></span>';
                                        }
                                    ?>
                                        </td>
                                        <td><?php echo $res['tier']; ?></td>
                                        <td><?php echo checkGetJobStatus($list->id); ?></td>
                                        <td>{{$list->mobile}}</td>
                                        <td>{{$list->email}}</td>
                                         <!-- <td>
                                            @if($list->has_payment)
                                            <span class="badge badge-success">Yes</span>
                                            @else
                                            <span class="badge badge-warning">No</span>
                                            @endif

                                        </td> -->
                                        <td>{{date('d-m-Y',strtotime($list->Created_at))}}</td>
										<td>{{date('d-m-Y',strtotime($list->subscription_date))}}</td>
                                        <td>
                                            @if ($list->status == '1')
                                            <a href="{{url('admin/status_driver',$list->id)}}"
                                                onclick="return confirm('Are you sure you want to Inactive this Record?');"
                                                class="badge badge-success text-white">Active</a>
                                            @else
                                            <a href="{{url('admin/status_driver',$list->id)}}"
                                                onclick="return confirm('Are you sure you want to Active this Record?');"
                                                class="badge badge-warning">Inactive</a>
                                            @endif
                                        </td>

                                        <td class="text-end">
                                            <div class=" ">
                                                <a class="edit-btn"
                                                    href="{{url('admin/update-truck-driver')}}/{{$list->id}}">
                                                    Edit
                                                </a>&nbsp;&nbsp;&nbsp;&nbsp;
                                                <a class="delete-btn"
                                                    href="{{url('/admin/delete-truck-driver')}}/{{$list->id}}"
                                                    onclick="return confirm('Are you sure to delete the record?')"
                                                    class="btn btn-sm bg-danger-light">
                                                    Delete
                                                </a>
                                            </div>
                                        </td>
                                    </tr>
                                    @endforeach
                                    @endif
                                </tbody>
                            </table>

                            <!-- Pagination Links -->
                            <div class="d-flex justify-content-center mt-3">
                                {!! $driver->links('pagination::bootstrap-5') !!}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@include('Admin.layouts.footer')
<!-- Filter Modal -->
<div class="modal fade" id="filterModal" tabindex="-1" aria-labelledby="filterModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">

            <div class="modal-header">
                <h5 class="modal-title" id="filterModalLabel">Filter Drivers</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>

            <div class="modal-body">
                <form action="{{ url('admin/subscribed-drivers') }}" method="GET" id="filterForm">
                    <div class="row">
                        <!-- Driver Added By -->
                        <div class="mb-3 col-md-6">
                            <label for="addedBy" class="form-label">Driver Added By</label>
                            <select class="form-select" name="added_by" id="addedBy">
                                <option value="">Select</option>
                                <option value="transporter"
                                    {{ ($filter_added_by ?? '') == 'transporter' ? 'selected' : '' }}>Transporter
                                </option>
                                <option value="self" {{ ($filter_added_by ?? '') == 'self' ? 'selected' : '' }}>Self
                                </option>
                            </select>
                        </div>

                        <!-- State Name -->
                        <div class="mb-3 col-md-6">
                            <label for="stateName" class="form-label">State Name</label>
                            <select class="form-select" id="stateName" name="state_name">
                                <option value="">Select State</option>
                                @foreach ($states as $state)
                                <option value="{{ $state->id }}"
                                    {{ (isset($filter_state) && $filter_state == $state->id) ? 'selected' : '' }}>
                                    {{ $state->name }}
                                </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- From Date -->
                        <div class="mb-3 col-md-6">
                            <label for="fromDate" class="form-label">From Date</label>
                            <input type="date" class="form-control" id="fromDate" name="from_date"
                                value="{{ request()->from_date }}">
                        </div>

                        <!-- To Date -->
                        <div class="mb-3 col-md-6">
                            <label for="toDate" class="form-label">To Date</label>
                            <input type="date" class="form-control" id="toDate" name="to_date"
                                value="{{ request()->to_date }}">
                        </div>

                        <!-- Status -->
                        <div class="mb-3 col-md-6">
                            <label for="status" class="form-label">Status</label>
                            <select class="form-select" id="status" name="status">
                                <option value="">Select Status</option>
                                <option value="active" {{ request('status') == 'active' ? 'selected' : '' }}>Active
                                </option>
                                <option value="inactive" {{ request('status') == 'inactive' ? 'selected' : '' }}>
                                    Inactive</option>
                            </select>
                        </div>

                        <!-- Rating Filter -->
                        <!-- Rating Filter -->
                        <div class="mb-3 col-md-6">
                            <label for="rating" class="form-label">Rating</label>
                            <select class="form-select" id="rating" name="rating">
                                <option value="">Select Rating</option>
                                @for ($i = 1; $i <= 5; $i++) <option value="{{ $i }}"
                                    {{ request('rating') == $i ? 'selected' : '' }}>
                                    {{ $i }} Star
                                    </option>
                                    @endfor
                            </select>
                        </div>

                        <!-- Ranking Filter -->
                        <div class="mb-3 col-md-12">
                            <label for="tier" class="form-label">Ranking</label>
                            <select class="form-select" id="tier" name="tier">
                                <option value="">Select Ranking</option>
                                <option value="Bronze" {{ request('tier') == 'Bronze' ? 'selected' : '' }}>Bronze
                                </option>
                                <option value="Silver" {{ request('tier') == 'Silver' ? 'selected' : '' }}>Silver
                                </option>
                                <option value="Gold" {{ request('tier') == 'Gold' ? 'selected' : '' }}>Gold</option>
                                <option value="Diamond" {{ request('tier') == 'Diamond' ? 'selected' : '' }}>Diamond
                                </option>
                            </select>
                        </div>
                        <!--Payment status-->
                        <!-- <div class="mb-3 col-md-6">
                            <label for="payment_status" class="form-label">Payment Status</label>
                            <select class="form-select" id="payment_status" name="payment_status">
                                <option value="">Select Payment Status</option>
                                <option value="captured"
                                    {{ request('payment_status') == 'captured' ? 'selected' : '' }}>Received</option>
                                <option value="not_received"
                                    {{ request('payment_status') == 'not_received' ? 'selected' : '' }}>Not Received
                                </option>
                            </select>
                        </div> -->
                </form>
            </div>

            <div class="modal-footer">
                <a href="{{ url('admin/subscribed-drivers') }}" class="btn btn-secondary btn-sm">
                    Clear Filters
                </a>
                <button style="background-color: #1a6dba !important; border:0 !important; outline:0 !important"
                    type="submit" form="filterForm" class="btn btn-primary btn-sm">Apply Filters</button>
            </div>
        </div>
    </div>
</div>


<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
<script src="https://cdn.datatables.net/plug-ins/1.13.1/sorting/datetime-moment.js"></script>
<script>
function initializeDataTable() {
    if ($.fn.DataTable.isDataTable('#dfUsageTable')) {
        $('#dfUsageTable').DataTable().destroy();
    }

    $('#dfUsageTable').DataTable({
        searching: false,
        paging: false,
        info: false,
        ordering: false,
        lengthChange: false,
        order: [],
        columnDefs: [{
            targets: 9, // date wali column
            render: function(data, type, row) {
                return type === 'sort' ?
                    moment(data, 'DD-MM-YYYY').format('YYYYMMDD') :
                    data;
            }
        }]
    });
}

$(document).ready(function() {
    initializeDataTable();

    $('#reinitializeButton').on('click', function() {
        initializeDataTable();
    });
});
</script>
<style>
.actions a {
    width: auto;
    height: auto;
}

table.dataTable thead .sorting,
table.dataTable thead .sorting_asc,
table.dataTable thead .sorting_desc {
    background-image: none !important;
}

.dataTables_length {
    display: none !important;
}

.actions a:hover {
    background: none !important;
}
</style>
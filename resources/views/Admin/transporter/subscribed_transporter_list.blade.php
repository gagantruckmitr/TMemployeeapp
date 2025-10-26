@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                    <div class="page-sub-header">
                        <h3 class="page-title">Transporter</h3>
                        <!--<ul class="breadcrumb">-->
                        <!--    <li class="breadcrumb-item active">All Transporter</li>-->
                        <!--</ul>-->
                    </div>
                </div>
            </div>
        </div>
        @if(Session::has('success'))
        <div class="alert alert-success">
            {{ Session::get('success') }}
        </div>
        @endif
        <div class="row">
            <div class="col-sm-12">
                <div class="card card-table comman-shadow">
                    <div class="card-body">
                        <div class="page-header">
                            <div class="row align-items-center">
                                <div class="col">
                                    <h3 class="page-title">Transporter List</h3>
                                </div>

                                <div class="col-auto d-flex gap-2">
                                    {{-- Show Clear Filter Button only if filters are applied --}}
                                    @if(request()->filled('state') || request()->filled('status') ||
                                    request()->filled('from_date') || request()->filled('to_date'))
                                    <a href="{{ url('admin/transporter') }}" class="btn btn-outline-secondary btn-sm">
                                        Clear Filter
                                    </a>
                                    @endif

                                    {{-- Filter Button --}}
                                    <button
                                        style="background-color: #1a6dba !important; border:0 !important; outline:0 !important"
                                        type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal"
                                        data-bs-target="#transporterFilterModal">
                                        <i class="fas fa-filter me-1"></i> Filter
                                    </button>
                                    <form action="{{ route('subscribed-transporters.export') }}" method="GET"
                                        style="display:inline-block;">
                                        <input type="hidden" name="state" value="{{ request()->input('state') }}">
                                        <input type="hidden" name="status" value="{{ request()->input('status') }}">
                                        <input type="hidden" name="from_date"
                                            value="{{ request()->input('from_date') }}">
                                        <input type="hidden" name="to_date" value="{{ request()->input('to_date') }}">

                                        <button class="btn btn-success btn-sm" type="submit">Export to Excel</button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped"
                            id="dfUsageTable">
                            <thead class="student-thread">
                                <tr>
                                    <!-- <th>
                                    <div class="form-check check-tables">
                                        <input class="form-check-input" type="checkbox" value="something">
                                    </div>
                                </th> -->
                                    <!--<th>S No.</th>-->
                                    <th>TM ID</th>
                                    <th>Image</th>
                                    <th>Name</th>
                                    <th>State</th>
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
                                @php $i = 1;
                                @endphp
                                @if(isset($transporter))
                                @foreach($transporter as $key=>$list)
                                <tr>
                                    <!-- <td>
                                    <div class="form-check check-tables">
                                        <input class="form-check-input" type="checkbox" value="something">
                                    </div>
                                </td> -->
                                    <!--<td>{{ $i++ }}</td>-->
                                    <td><a style="color:#3d5ee1;"
                                            href="{{ url('admin/transporter-job')}}/{{ $list->id }}">{{ $list->unique_id }}</a>
                                    </td>

                                    <td>
                                        <h2 class="table-avatar">
                                            @php
                                            $imagePath = !empty($list->image) && is_string($list->image)
                                            ? url('/public/driver_images/' . $list->image)
                                            : url('/public/noimg.png');
                                            @endphp

                                            <a href="#" class="avatar avatar-sm me-2">
                                                <img class="avatar-img rounded-circle" src="{{ $imagePath }}"
                                                    alt="User Image">
                                            </a>
                                        </h2>
                                    </td>
                                    <td>{{$list->name}}</td>
                                    <td>{{ $list->state_name ?? 'N/A' }}</td>
                                    <td>{{$list->mobile}}</td>
                                    <td>{{$list->email}}</td>
                                     <!-- <td>
                                        @if($list->has_payment)
                                        <span class="badge badge-success">Yes</span>
                                        @else
                                        <span class="badge badge-warning">No</span>
                                        @endif
                                    </td> -->
                                    <!-- <td>{{ \Carbon\Carbon::parse($list->Created_at)->setTimezone('Asia/Kolkata')->format('d-m-Y') }}
                                    </td> -->
                                    <td>{{date('d-m-Y',strtotime($list->Created_at))}}</td>
                                    <td>{{date('d-m-Y',strtotime($list->subscription_date))}}</td>
                                    <td>
                                        @if ($list->status == '1')
                                        <a href="{{url('admin/status_transporter',$list->id)}}"
                                            onclick="return confirm('Are you sure you want to Inactive this Record?');"
                                            class="badge badge-success text-white">Active</a>
                                        @else
                                        <a href="{{url('admin/status_transporter',$list->id)}}"
                                            onclick="return confirm('Are you sure you want to Active this Record?');"
                                            class="badge badge-warning">Inactive</a>
                                        @endif
                                    </td>
                                    <!--<td>{{$list->status==1?'Active':'In-active'}}</td>-->
                                    <td class="text-end">
                                        <div class=" ">
                                            <a href="{{url('admin/edit-transporter')}}/{{$list->id}}" class="edit-btn">
                                                Edit
                                            </a>&nbsp;&nbsp;&nbsp;
                                            <a class="delete-btn"
                                                href="{{url('/admin/delete_transporter')}}/{{$list->id}}"
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
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</div>

<!-- Transporter Filter Modal -->
<div class="modal fade" id="transporterFilterModal" tabindex="-1" aria-labelledby="transporterFilterModalLabel"
    aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form action="{{ url('admin/transporter') }}" method="GET">
                <div class="modal-header">
                    <h5 class="modal-title" id="transporterFilterModalLabel">Filter Transporters</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body">
                    <div class="row g-3">
                        <!-- State Dropdown -->
                        <div class="col-md-6">
                            <label for="state" class="form-label">State</label>
                            <select class="form-select" name="state" id="state">
                                <option value="">Select State</option>
                                @foreach ($states as $state)
                                <option value="{{ $state->name }}"
                                    {{ request('state') == $state->name ? 'selected' : '' }}>
                                    {{ $state->name }}
                                </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- Status Dropdown -->
                        <div class="col-md-6">
                            <label for="status" class="form-label">Status</label>
                            <select class="form-select" name="status" id="status">
                                <option value="">Select Status</option>
                                <option value="active" {{ request('status') == 'active' ? 'selected' : '' }}>Active
                                </option>
                                <option value="inactive" {{ request('status') == 'inactive' ? 'selected' : '' }}>
                                    Inactive</option>
                            </select>
                        </div>

                        <!-- From Date -->
                        <div class="col-md-6">
                            <label for="from_date" class="form-label">From Date</label>
                            <input type="date" class="form-control" name="from_date" id="from_date"
                                value="{{ request('from_date') }}">
                        </div>

                        <!-- To Date -->
                        <div class="col-md-6">
                            <label for="to_date" class="form-label">To Date</label>
                            <input type="date" class="form-control" name="to_date" id="to_date"
                                value="{{ request('to_date') }}">
                        </div>
                        <!--payment Filter-->
                        <div class="col-md-12">
                            <label for="payment_status" class="form-label">Subscription Status</label>
                            <select class="form-select" id="payment_status" name="payment_status">
                                <option value="">Select Subscription Status</option>
                                <option value="captured"
                                    {{ request('payment_status') == 'captured' ? 'selected' : '' }}>Yes</option>
                                <option value="not_received"
                                    {{ request('payment_status') == 'not_received' ? 'selected' : '' }}>No</option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="modal-footer d-flex">
                    <a href="{{ url('admin/transporter') }}" class="btn btn-outline-secondary btn-sm">
                        Clear Filter
                    </a>
                    <button style="background-color: #1a6dba !important; border:0 !important; outline:0 !important"
                        type="submit" class="btn btn-primary btn-sm">
                        Apply Filter
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


@include('Admin.layouts.footer')
<script>
function changestatus(status, pid) {

    $.ajax({
        url: '/institute/update-status/' + pid + '/' + status,
        type: "GET",
        contentType: false,
        cache: false,
        processData: false,
        async: true,
        success: function(data) {

            location.reload();

        }
    });

}
</script>
<script>
function initializeDataTable() {
    if ($.fn.DataTable.isDataTable('#dfUsageTable')) {
        $('#dfUsageTable').DataTable().destroy();
    }

    // Initialize the DataTable
    $('#dfUsageTable').DataTable({
        destroy: true,
        searching: true,
        paging: true,
        info: true,
        ordering: false
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

.actions a:hover {
    background: none !important;
}

.badge-success {
    background-color: #7bb13c !important;
    color: #fff !important;
}

.badge-warning {
    background-color: #ffbc34 !important;
    color: #fff !important;
}
</style>
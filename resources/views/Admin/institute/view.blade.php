@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Driver Training School</h3>
                    <!--<ul class="breadcrumb">-->
                    <!--    <li class="breadcrumb-item active">Driver Training School</li>-->
                    <!--</ul>-->
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
                            <h3 class="page-title">DTS List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
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
                                <th>Mobile</th>
                                <th>Email</th>
                                <th>Date</th> 
                                <th>Status</th> 
                                <th class="text-end">Action</th>
                            </tr>
                            </thead>
                            <tbody>
                                 @php $i = 1;
                            @endphp
                            @if(isset($institutes))
                            @foreach($institutes as $key=>$list)
                            <tr>
                                <!-- <td>
                                    <div class="form-check check-tables">
                                        <input class="form-check-input" type="checkbox" value="something">
                                    </div>
                                </td> -->
                                <!--<td>{{ $i++ }}</td>-->
                                <td><a style="color:green;" href="{{ url('admin/view-institute-driver')}}/{{ $list->id }}">{{ $list->unique_id }}</a></td>

                                <td>
                                    <h2 class="table-avatar">
                                        <a href="#" class="avatar avatar-sm me-2"><img class="avatar-img rounded-circle" src="{{$list->image!=''?url('/public/driver_images/'.$list->image):url('/public/noimg.png')}}" alt="User Image"></a>
                                    </h2>
                                </td>
                                <td>{{$list->name}}</td>
                                <td>{{$list->mobile}}</td>
                                <td>{{$list->email}}</td>
                                <td>{{ \Carbon\Carbon::parse($list->Created_at)->setTimezone('Asia/Kolkata')->format('d-m-Y') }}</td>
                                <?php if($list->status == 0){ ?>
                                  <td><span style="cursor:pointer;" onclick="changestatus(1,<?php echo $list->id; ?>)" class="badge badge-warning">Inactive</span></td>
                                   <?php }else{ ?>
                                  <td><span style="cursor:pointer;" onclick="changestatus(0,<?php echo $list->id; ?>)" class="badge badge-success">Active</span></td>
                                <?php } ?>
                                <!--<td>{{$list->status==1?'Active':'In-active'}}</td>-->
                                <td class="text-end">
                                    <div class=" ">
                                        <a href="{{url('admin/edit-truck-institute')}}/{{$list->id}}" class="edit-btn">
                                        <!--<i style="font-size: 25px;color: green;" class="feather-edit"></i>-->View/Edit Profile
                                        </a>
                                        <!--<a class="delete-btn" href="{{url('/admin/delete-truck-institute')}}/{{$list->id}}" onclick="return confirm('Are you sure?')" class="btn btn-sm bg-danger-light">-->
                                        <!--Delete-->
                                        <!--</a>-->
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
        
@include('Admin.layouts.footer')
<script>
    function changestatus(status,pid)
    {
        
        $.ajax({
            url: '/institute/update-status/'+pid+'/'+status,
            type: "GET",
            contentType: false,
            cache: false,
            processData: false,
            async: true,
            success: function (data) { 
                
                location.reload();

            }
        });
        
    }
</script>
<script>
     function initializeDataTable() {
            // Check if DataTable is already initialized
            if ($.fn.DataTable.isDataTable('#dfUsageTable')) {
                // If yes, destroy the existing instance before reinitializing
                $('#dfUsageTable').DataTable().destroy();
            }

            // Initialize the DataTable
            $('#dfUsageTable').DataTable({
                destroy: true, // Allows reinitialization
                searching: true, // Enables the search box
                paging: true, // Enables pagination
                info: true, // Enables table information
            });
        }

        // Initialize DataTable on document ready
        $(document).ready(function() {
            initializeDataTable();

            // Reinitialize DataTable on button click
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
        
        .actions a:hover{
            background:none !important;
        }
    </style>

@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Driver</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item active">All Driver</li>
                    </ul>
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
                            <h3 class="page-title">Driver List</h3>
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
                                 <th>Rating</th>
                                <th>Ranking</th>
                                <th>Mobile</th>
                                <th>Email</th> 
                                <th>Status</th> 
                                <!--<th class="text-end">Action</th>-->
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @if(isset($driver))
                            @foreach($driver as $key=>$list)
                             <?php $res = get_rating_and_ranking_by_all_module($list->id); ?>
                            <tr>
                                <!-- <td>
                                    <div class="form-check check-tables">
                                        <input class="form-check-input" type="checkbox" value="something">
                                    </div>
                                </td> -->
                                <!--<td>{{ $i++ }}</td>-->
                                <td>{{$list->unique_id}}</td>
                                <td>
                                    <h2 class="table-avatar">
                                        <a href="#" class="avatar avatar-sm me-2"><img class="avatar-img rounded-circle" src="{{$list->image!=''?url('/public/driver_images/'.$list->image):url('/public/noimg.png')}}" alt="User Image"></a>
                                    </h2>
                                </td>
                                <td>{{$list->name}}</td>
                                <td><?php 
                                        for ($i = 0; $i < $res['rating']; $i++) { 
                                            echo '<span class="fa fa-star checked"></span>';
                                        }
                                        for ($i = $res['rating']; $i < 5; $i++) { 
                                            echo '<span class="fa fa-star"></span>';
                                        } ?></td>
                                <td><?php echo $res['tier']; ?></td>
                                <td>{{$list->mobile}}</td>
                                <td>{{$list->email}}</td>
                               <td>
                                @if ($list->status == '0')
                                   <a class="badge badge-success">Active</a>
                                @else
                                    <a class="badge badge-warning">Inactive</a>
                                @endif
                                </td>
                                <!--<td class="text-end">-->
                                <!--    <div class="actions ">-->
                                <!--        <a href="{{url('admin/edit-truck-institute')}}/{{$list->id}}" class="btn btn-sm bg-danger-light">-->
                                <!--        <i class="feather-edit"></i>-->
                                <!--        </a>-->
                                <!--        <a href="{{url('/admin/delete-truck-institute')}}/{{$list->id}}" onclick="return confirm('Are you sure?')" class="btn btn-sm bg-danger-light">-->
                                <!--        <i class="feather-delete"></i>-->
                                <!--        </a>-->
                                <!--    </div>-->
                                <!--</td>-->
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
@include('Admin.layouts.footer')

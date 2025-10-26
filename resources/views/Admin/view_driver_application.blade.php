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
                    <!--<ul class="breadcrumb">-->
                        
                    <!--    <li class="breadcrumb-item active">All Driver</li>-->
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
                                <!--<th>S No</th>-->
                                <th>TM ID</th>
                                <th>Driver Added By</th>
                                <th>Image</th>
                                <th>Name</th>
                                <th>Rating</th>
                                <th>Ranking</th>
                                <th>Job Status</th>
								<th>Subscription Status</th>
                                <th>Mobile</th>
                                <th>Email</th> 
                            </tr>
                            </thead>
                            <tbody>
                            @if(isset($driver))
                            @foreach($driver as $key=>$list)
                            
                            <?php $res = get_rating_and_ranking_by_all_module($list->id); ?>
                            <tr>
                                <!-- <td>
                                    <div class="form-check check-tables">
                                        <input class="form-check-input" type="checkbox" value="something">
                                    </div>
                                </td> -->
                                <!-- <td>{{$list->id}}</td> -->
                                <td><a href="/admin/update-truck-driver/{{$list->id}}">{{$list->unique_id}}</a></td>
                                <td><?php echo $list->sub_id?'Institute':'Self';?></td>
                                <td>
                                    <h2 class="table-avatar">
                                        <a href="#" class="avatar avatar-sm me-2"><img class="avatar-img rounded-circle" src="{{$list->images!=''?url('/public/'.$list->images):url('/public/noimg.png')}}" alt="User Image"></a>
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
                               <td><?php  echo ucfirst(checkAppliedJobStatus($list->id,$jobId));?> </td>
								  <td>
                                    @if($list->payment_status === 'captured')
                                        <span class="badge bg-success">Subscribed</span>
                                    @else
                                        <span class="badge bg-warning text-dark">Unsubscribed</span>
                                    @endif
                                </td>
                                <td>{{$list->mobile}}</td>
                                <td>{{$list->email}}</td>
                                
                                
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
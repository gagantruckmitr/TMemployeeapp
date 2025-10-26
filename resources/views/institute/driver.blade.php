@include('institute.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Driver</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('institute/add-driver')}}">Add Driver</a></li>
						 <li class="breadcrumb-item active">All Driver</li>
                    </ul>
                </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            @if (session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
            @endif
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
                                <th>TM ID</th>
                                <th>Images</th>
                                <th>Name</th>
                                <th>Rating</th>
                                <th>Ranking</th>
                                <th>mobile</th>
                                <th>Email</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                           @foreach ($user as $key => $value)
                           <?php $res = get_rating_and_ranking_by_all_module($value->id); ?>
                            <tr>
                                
                                <td>{{$value->unique_id}}</td>
                                <td><img src="{{ url('public/'.$value->images) }}" alt="" width="150" height="100"></td>
                                <td>{{$value->name}}</td>
                                <td><?php 
                                        for ($i = 0; $i < $res['rating']; $i++) { 
                                            echo '<span class="fa fa-star checked"></span>';
                                        }
                                        for ($i = $res['rating']; $i < 5; $i++) { 
                                            echo '<span class="fa fa-star"></span>';
                                        } ?></td>
                                        
							<td><?php echo $res['tier']; ?></td>
								<td>{{$value->mobile}}</td>
                                <td>{{$value->email}}</td>
                                <td><a class="edit-btn" href="{{url('institute/driver/edit')}}/{{$value->id}}">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;
								
								<a class="delete-btn" href="{{url('institute/driver/delete')}}/{{$value->id}}" onclick="return confirm('Are you sure you want to delete this Record?');">Delete</a></td>
                            </tr>
                           @endforeach 
                            </tbody>
                        </table>
                    </div>
                </div>
                </div>
            </div>
        </div>
    </div>
</div>        
        
@include('institute.layouts.footer')

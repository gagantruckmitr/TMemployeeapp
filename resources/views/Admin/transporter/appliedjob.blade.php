@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Applied Job</h3>
                    <ul class="breadcrumb">
                        <!--<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('transporter/add-job')}}">Add Job</a></li>-->
						 <li class="breadcrumb-item active">All Job</li>
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
                            <h3 class="page-title">Applied Job List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>S No</th>
                                <th>TM Id</th>
                                <th>Job Title</th>
                                <th>Driver Name</th>
                                <th>Applied Date</th>
                            </tr>
                            </thead>
                            <tbody>
                              @php $i = 1;
                                @endphp
                           @foreach ($job as $key => $value)
                            <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{ $value->unique_id }}</td>
                                <td>{{$value->job_title}}</td>
								<td>{{$value->name}}</td>
                                <td>{{$value->created_at}}</td>
        <!--                        </?php if($value->status == 0){ ?>-->
        <!--                          <td><span style="cursor:pointer;"  class="badge badge-warning">Inactive</span></td>-->
        <!--                           </?php }else{ ?>-->
        <!--                          <td><span style="cursor:pointer;"  class="badge badge-success">Active</span></td>-->
        <!--                        </?php } ?>-->

        <!--                        <td><a href="{{url('transporter/job/edit')}}/{{$value->id}}"><i style="color:green;font-size:28px;" class="fas fa-edit"></i></a>&nbsp;&nbsp;&nbsp;&nbsp;-->
								
								<!--<a href="{{url('transporter/job/delete')}}/{{$value->id}}" onclick="return confirm('Are you sure you want to delete this Record?');"><i style="color:red;font-size:28px;" class="fas fa-trash"></i></a></td>-->
                            
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
        
@include('Admin.layouts.footer')

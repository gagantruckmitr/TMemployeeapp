@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Quiz</h3>
       <!--             <ul class="breadcrumb">-->
       <!--                 <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/add-quiz')}}">Add Quiz</a></li>-->
						 <!--<li class="breadcrumb-item active">All Quiz</li>-->
       <!--             </ul>-->
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
                            <h3 class="page-title">Quiz List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>Id</th>
                                <th>Modules</th>
                                <th>Topic</th>
                                <th>Question Name</th>
                                <th>Question image</th>
                                <th>Option 1</th> 
                                <th>Option 2</th> 
                                <th>Option 3</th> 
                                <th>Option 4</th> 
                                <th>Answer</th> 
                                
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                               @php $i = 1;
                                @endphp
                           @foreach ($Quiz as $key => $value)
                            <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{$value->name}}</td>
                                <td>{{$value->topic_name}}</td>
                                <td>{{$value->question_name}}</td>
                                <td><img src="{{ url('public/'.$value->question_image) }}" alt="" width="150" height="100"></td>
								<td>{{$value->option1}}</td>
								<td>{{$value->option2}}</td>
								<td>{{$value->option3}}</td>
								<td>{{$value->option4}}</td>
								<td>{{$value->Answer}}</td>
							
                                <td class="text-end">
                                    <div class=" ">
                                    <a class="edit-btn" href="{{url('admin/quiz/edit')}}/{{ $value->id }}">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;
								<a class="delete-btn" href="{{url('admin/delete_quiz')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">
								    Delete
                                       </a>
                                       </div>
							</td>
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

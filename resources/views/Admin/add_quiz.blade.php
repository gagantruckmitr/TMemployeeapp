@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Quiz</h3>
     <!--               <ul class="breadcrumb">-->
					<!--<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/quiz')}}">List Quiz</a></li>-->
     <!--                   <li class="breadcrumb-item active">Add Quiz</li>-->
     <!--               </ul>-->
                </div>
                </div>
            </div>
        </div>
        
             <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Add Quiz</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/create_quiz')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="topic" class="form-label">Select Modules <span class="text-danger">*</span></label>
                                            <select class="form-select" name="module" id="module">
                                                <option>Select Modules</option>
                                                @foreach ($Module as $key => $value)
                                                <option value="{{$value->id}}">{{$value->name}}</option>
                                                @endforeach 
                                            </select>
                                            @if($errors->has('topic'))
                                                <div class="text-danger">{{ $errors->first('topic') }}</div>
                                            @endif
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="topic" class="form-label">Select Topic <span class="text-danger">*</span></label>
                                            <select class="form-select" name="topic" id="topic">
                                                
                                            </select>
                                            @if($errors->has('topic'))
                                                <div class="text-danger">{{ $errors->first('topic') }}</div>
                                            @endif
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Question<span class="login-danger">*</span></label>
                                           <input type="text" name="question_name" class="form-control" value="{{old('question_name')}}">
										   @if($errors->has('question_name'))
											  <span class="text-danger">{{ $errors->first('question_name') }}</span>
											@endif
                                        </div>
                                   </div>
                                   
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Question Image (Size: 400*200 )</label>
                                           <input type="file" name="question_image" class="form-control" value="{{old('question_image')}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Option 1<span class="login-danger">*</span> </label>
                                           <input type="text" name="option1" class="form-control" value="{{old('option1')}}">
										   @if($errors->has('option1'))
											  <span class="text-danger">{{ $errors->first('option1') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Option 2<span class="login-danger">*</span> </label>
                                           <input type="text" name="option2" class="form-control" value="{{old('option2')}}">
										   @if($errors->has('option2'))
											  <span class="text-danger">{{ $errors->first('option2') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Option 3<span class="login-danger">*</span> </label>
                                           <input type="text" name="option3" class="form-control" value="{{old('option3')}}">
										   @if($errors->has('option3'))
											  <span class="text-danger">{{ $errors->first('option3') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Option 4<span class="login-danger">*</span> </label>
                                           <input type="text" name="option4" class="form-control" value="{{old('option4')}}">
										   @if($errors->has('option4'))
											  <span class="text-danger">{{ $errors->first('option4') }}</span>
											@endif
                                        </div>
                                   </div>
                                     <div class="col-md-12">
                                        <div class="form-group">
                                           <label>Correct Answer<span class="login-danger">*</span> </label>
                                           <input type="text" name="Answer" class="form-control" value="{{old('Answer')}}">
										   @if($errors->has('Answer'))
											  <span class="text-danger">{{ $errors->first('Answer') }}</span>
											@endif
                                        </div>
                                   </div>                                 
                                    <div class="text-start">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
                    </div>
                </div>
        </div>
</div>
        
@include('Admin.layouts.footer')
<script>
    document.getElementById('module').addEventListener('change', function () {
        
    let moduleId = this.value;
  
    // Clear previous topics
    let topicDropdown = document.getElementById('topic');
    topicDropdown.innerHTML = '';

    if (moduleId) {
        
        fetch(`/get-topics?module_id=${moduleId}`)
        
            .then(response => response.json())
            .then(data => {
                for (let id in data) {
                    let option = document.createElement('option');
                    option.value = id;
                    option.text = data[id];
                    topicDropdown.appendChild(option);
                }
            })
            .catch(error => console.error('Error fetching topics:', error));
    }
});

</script>

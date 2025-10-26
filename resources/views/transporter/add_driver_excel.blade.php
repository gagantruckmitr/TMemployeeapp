@include('transporter.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Add Driver</h3>
                    <ul class="breadcrumb">
					
                </div>
                </div>
            </div>
        </div>
        
        <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Upload Excel Sheet</h5><br><a href="/public/assets/excel/Bulk Driver Registration Format.xlsx" download>Download Sample File</a>
                            
                            <p class="pt-2"><strong>Instructions</strong></p>
                            
                            <ol>
                                <li>1. Download the Excel file. </li>
                                <li>2. Fill in the details, including Name, Email, Mobile Number, and State Code.</li>
                                <li>3. Refer to <strong>Sheet2</strong> to check and copy the correct State Code</li>
                                <li>4. <strong>Name, Mobile Number, and State Code are mandatory fields and cannot be left blank.</strong></li>
                                <li>5. The <strong>Email field is optional.</strong></li>
                                <li>6. After entering the details, save the file in Excel format and upload it.</li>
                                
                            </ol>
                            
                            <p><strong>Note: </strong>The system will validate the mobile number and remove any entries that are invalid mobile number or already exist in the system.</p>
                            
                        </div>
                        <div class="card-body">
                           <form action="{{url('transporter/import-driver')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="col-md-12">
                                            <div class="form-group">
                                               <label>Excel<span class="login-danger">*</span></label>
                                               @if ($errors->any())
                                                    <div class="alert alert-danger">
                                                        <strong>Some rows were not imported due to errors:</strong>
                                                        <ul>
                                                            @foreach ($errors->all() as $error)
                                                                <li>{{ $error }}</li>
                                                            @endforeach
                                                        </ul>
                                                    </div>
                                                @endif

                                                @if(session('success'))
                                                    <div class="alert alert-success">
                                                        {{ session('success') }}
                                                    </div>
                                                @endif


                                               @if(session('success'))
                                                    <p style="color: green;">{{ session('success') }}</p>
                                                @elseif(session('error'))
                                                    <p style="color: red;">{{ session('error') }}</p>
                                                @endif
                                               <input type="file" name="file" class="form-control">
    										   @if($errors->has('excel'))
    											  <span class="text-danger">{{ $errors->first('excel') }}</span>
    											@endif
                                            </div>
                                       </div>
                                   </div>
                                    <div class="text-end">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
                    </div>
                </div>
                
        </div>
        
        
        
        
</div>
        
@include('transporter.layouts.footer')

@include('institute.layouts.header')

        <div class="page-wrapper">
            <div class="content container-fluid">

                <div class="page-header">
                    <div class="row">
                        <div class="col-sm-12">
                            <div class="page-sub-header">
                                <h3 class="page-title"><!--Name:- <span style="color:green;">{{$user->name}}</span>--> <span>{{$user->Training_Institute_Name}},</span> Welcome To TruckMitr</h3>
							
                                <ul class="breadcrumb">
								
                                    <li class="breadcrumb-item"><a href="#">Institute</a></li>
                                    <li class="breadcrumb-item active">Dashboard</li>
                                </ul>
                            </div>
                        </div>
                        <h6>TM ID : {{$user->unique_id}}</h6>
                        
                    </div>
                </div>


               <div class="row">
                    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6><a class="dshbrd-link" href="{{url('institute/driver')}}">Total Driver</a></h6>
                                        <h3>{{$totaldriver}}</h3>
                                    </div>
                                    <div class="db-icons">
                                        <i class="fas fa-user-shield"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                     <!--<div class="col-xl-4 col-sm-6 col-12 d-flex">
                        
                    </div>
					<div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6>Training ID</h6>
                                        <h3>TB-00001</h3>
                                    </div>
                                    <div class="db-icons">
                                        Member Since:- August 2024
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div style="padding: 30px;" class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6 style="text-align: center">25/100</h6>
                                        <h3>Training Videos Completed</h3>
                                    </div>
                                    
                                </div>
                            </div>
                        </div>
                    </div>
					<div class="col-xl-2 col-sm-6 col-12 d-flex">
                        
                    </div>
					<div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div style="padding: 30px;" class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6 style="text-align: center">1000+</h6>
                                        <h3>Jobs Available</h3>
                                    </div>
                                    
                                </div>
                            </div>
                        </div>
                    </div>
					<div class="col-xl-2 col-sm-6 col-12 d-flex">
                        
                    </div>
					<div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div style="padding: 30px;" class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6 style="text-align: center">20/100</h6>
                                        <h3>Quizzes Completed</h3>
                                    </div>
                                    
                                </div>
                            </div>
                        </div>
                    </div>
					<div class="col-xl-2 col-sm-6 col-12 d-flex">
                        
                    </div>
					<div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h3>health & Hygiene Points Earned</h3>
                                        <h6 style="padding: 5px;">- Points Collected Till Date - 100</h6>
										<h6 style="padding-righ: 5px;">- Points Required To Reach next<br>&nbsp;&nbsp;&nbsp;&nbsp;Certification Level - 100</h6>
                                    </div>
                                    
                                </div>
                            </div>
                        </div>
                    </div>
                    
                </div>-->

                
			
			</div>
@include('institute.layouts.footer')

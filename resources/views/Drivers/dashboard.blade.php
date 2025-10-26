@include('layouts.header')
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
        <div class="page-wrapper">
            <div class="content container-fluid">

                <div class="page-header">
                    <div class="row">
                        <div class="col-sm-12">
                            <div class="page-sub-header">
                                <h3 class="page-title"> {{$User->name;}}, Welcome To TruckMitr</h3><br>
                                
								<h6>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</h6>
                                <ul class="breadcrumb">
								
                                    <li class="breadcrumb-item"><a href="#">Drivers</a></li>
                                    <li class="breadcrumb-item active">Dashboard</li>
                                </ul>
                                
                            </div>
                            
                        </div>
                        <h6>ID : - {{$User->unique_id}}</h6>
                    </div>
                </div>


                <div class="row">
                    
					<!--<div class="col-xl-4 col-sm-6 col-12 d-flex">-->
     <!--                   <div class="card bg-comman w-100">-->
     <!--                       <div class="card-body">-->
     <!--                           <div class="db-widgets d-flex justify-content-between align-items-center">-->
     <!--                               <div class="db-info">-->
     <!--                                   <h6>Training ID</h6>-->
     <!--                                   <h3></h3>-->
     <!--                               </div>-->
     <!--                               <div class="db-icons">-->
     <!--                                   <img src="{{url('public/assets/img/icons/dash-icon-01.svg')}}" alt="Dashboard Icon">-->
     <!--                               </div>-->
     <!--                           </div>-->
     <!--                       </div>-->
     <!--                   </div>-->
     <!--               </div>-->
     
                    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <?php $res = get_rating_and_ranking_by_all_module(session('id')); ?>
                                        <h6>Rating : 
                                        <?php 
                                        for ($i = 0; $i < $res['rating']; $i++) { 
                                            echo '<span class="fa fa-star checked"></span>';
                                        }
                                        for ($i = $res['rating']; $i < 5; $i++) { 
                                            echo '<span class="fa fa-star"></span>';
                                        } ?></h6>
                                        <h3>Ranking: <?php echo $res['tier']; ?></h3>
                                    </div>
                                    <div class="db-icons">
                                        <i class="fas fa-award"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6><a class="dshbrd-link" href="{{url('driver/videos')}}">Training Videos</a></h6>
                                        <h3>{{getvideoCount()}}</h3>
                                    </div>
                                    <div class="db-icons">
                                        <i class="fas fa-video"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
     
                    
                    
                    
                    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6><a class="dshbrd-link" href="{{url('driver/quizcount')}}">Quizzes</a></h6>
                                        <h3>{{getTotalQuiz(Session::get('id'))}}</h3>
                                    </div>
                                    <div class="db-icons">
                                        <i class="fas fa-question-circle"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
				
				
				    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6><a class="dshbrd-link" href="{{url('driver/health-hygiene')}}">Health & Hygiene Training</a></h6>
                                        <h3>{{getHealthHygieneCount()}}</h3>
                                    </div>
                                    <div class="db-icons">
                                        <i class="fas fa-briefcase-medical"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h6><a class="dshbrd-link" href="{{url('driver/jobs-all')}}">Jobs Available</a></h6>
                                        <h3>{{$totaljob}}</h3>
                                    </div>
                                    <div class="db-icons">
                                        <i class="fas fa-briefcase"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!--<div class="col-xl-4 col-sm-6 col-12 d-flex">-->
                    <!--    <div class="card bg-comman w-100">-->
                    <!--        <div class="card-body">-->
                    <!--            <div class="db-widgets d-flex justify-content-between align-items-center">-->
                    <!--                <div class="db-info">-->
                    <!--                    <h6><a class="dshbrd-link" href="{{url('driver/videos')}}">Applied Jobs</a></h6>-->
                    <!--                    <h3>20</h3>-->
                    <!--                </div>-->
                    <!--                <div class="db-icons">-->
                    <!--                    <i class="fas fa-briefcase"></i>-->
                    <!--                </div>-->
                    <!--            </div>-->
                    <!--        </div>-->
                    <!--    </div>-->
                    <!--</div>-->
                  
                </div>

                
			
			</div>
@include('layouts.footer')

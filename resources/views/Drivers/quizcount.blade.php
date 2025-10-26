@include('layouts.header')

        <div class="page-wrapper">
            <div class="content container-fluid">

                <div class="page-header">
                    <div class="row">
                        <div class="col-sm-12">
                            <div class="page-sub-header">
                                <h3 class="page-title"> Quiz Results</h3>
								<h6>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</h6>
                                <!--<ul class="breadcrumb">-->
								
                                <!--    <li class="breadcrumb-item"><a href="#">Drivers</a></li>-->
                                <!--    <li class="breadcrumb-item active">Dashboard</li>-->
                                <!--</ul>-->
                            </div>
                        </div>
                    </div>
                </div>
                <div class="row">
                
				    
                    @if(isset($module))
                    @foreach($module as $module)
				    <div class="col-xl-4 col-sm-6 col-12 d-flex">
                        <div class="card bg-comman w-100">
                            <div class="card-body">
                                <div class="db-widgets d-flex justify-content-between align-items-center">
                                    <div class="db-info">
                                        <h3>{{$module->name}}</h3>
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
                                        <i class="fas fa-clipboard-check"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    @endforeach
                    @endif
					
					
				
                    
                </div>

                
			
			</div>
@include('layouts.footer')

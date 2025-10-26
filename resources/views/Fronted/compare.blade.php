@include('Fronted.header')

 <style>
 
 .compare-container {
    display: flex;
    justify-content: center;
}

 
    h1,h2 {font-size: 21px;margin-bottom: 16px;}
@media (max-width: 768px) {
      h1,h2 {font-size: 18px;margin-bottom: 16px;
      }}
p {font-size: 14px;}
.sectionShadow {box-shadow: 0 1px 3px rgba(36, 39, 44, 0.15);}
a {color: #212529;transition: 0.2s ease-in-out;text-decoration: none;}
a:hover,a:active {text-decoration: none;transition: 0.2s ease-in-out;}
.newTruckBlock-inner .newTruckBlock-img {background-color: #fff;
      text-align: center;position: relative;}
.newTruckBlock-inner .newTruckBlock-img img {max-width: 600px;
      width: 100%;max-height: 350px;height: auto;}
.newTruckBlock-inner .newTruckBlock-content {
      background-color: #f6f6f6;padding: 15px 15px;}
.newTruckBlock-inner .newTruckBlock-content .newTruckBlock-price {
      font-size: 15px;margin-bottom: 12px;white-space: nowrap;
      text-overflow: ellipsis;overflow: hidden;}
    @media (min-width: 992px) {
      .newTruckBlock-inner .newTruckBlock-btn {text-transform: capitalize !important;
      }}
.newTruckBlock-inner .newTruckBlock-btn {background: #1b7dbf;
      border: 1px solid #1b7dbf;color: #fff;cursor: pointer;}
.borderBtn {background: #ffffff;border: 1px solid #006db7;
      color: #006db7;padding: 0 10px;border-radius: 4px;line-height: 40px;
      display: block;font-size: 16px;font-family: "TJ-bold", Arial, Helvetica, sans-serif;
      white-space: nowrap;text-overflow: ellipsis;overflow: hidden;}
.borderBtn:hover {background: #005995;border: 1px solid #005995;color: #fff;
      /* box-shadow: 0 15px 20px rgba(177, 177, 177, .4); */}
.vsBlock {position: relative;}
.vsBlock::before {position: absolute;content: "VS";top: 50%;left: 50%;
      transform: translate(-50%, -50%);width: 50px;height: 50px;background-color: #333;
      text-align: center;font-family: "tj-bold", arial, helvetica, sans-serif;
      color: #fff;border-radius: 50%;padding-top: 14px;font-size: 18px;}
.newTruckBlock-inner .newTruckBlock-content .newTruckBlock-title {line-height: 1.5;}
    .newTruckBlock-inner .newTruckBlock-content .newTruckBlock-title {
      font-size: 17px;white-space: nowrap;text-overflow: ellipsis;
      overflow: hidden;margin-bottom: 5px;color: #006db7;}
.accordion-item,.accordion-button {border-radius: 0 !important;}
.accordion-item {margin-bottom: 20px;}
.accordion-button {background-color: #006db7 !important;color: #fff !important;}
    .accordion-button::after {
      background-image: url(https://static-asset.tractorjunction.com/tr/plus.svg);
      background-size: 13px;filter: invert(100%);}
    .accordion-button:not(.collapsed)::after {
      background-image: url(https://static-asset.tractorjunction.com/tr/minus.svg);
      transform: none;}
.headingbar {position: relative;}
.headingbar:after {content: "";display: block;position: absolute;width: 40px;
      height: 4px;left: 0;bottom: -10px;border-radius: 2px;background-clip: padding-box;
      background-color: #1b7dbf;}
.compareResult-inner {border: 1px solid #ddd;border-top: 0;padding: 10px;}
.compareResult-inner:nth-child(2n) {background-color: #f6f6f6;}
.boldfont {font-weight: bold;}
/*img.img-fluid {height: 353px !important;}*/
.backbtn{
    background:#1b7dbf;
    color:#fff;
    padding:8px 30px 8px 15px;
    font-size: 19px;
}
  </style>
  
  
  <!--Check offer Start-->
  
  <div class="modal fade" id="eicherModal" tabindex="-1" aria-labelledby="eicherModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
         
        <form method="POST" action="{{url('track_submit')}}">
            @csrf
          <div class="row">
            <div class="col-md-6 mb-3">
              <label for="name" class="form-label">Name<span class="text-danger">*</span></label>
              <input type="text" class="form-control" name="names" placeholder="Enter your name" required="">
            </div>
            <div class="col-md-6 mb-3">
              <label for="mobile" class="form-label">Mobile Number<span class="text-danger">*</span></label>
              <input type="tel" class="form-control" name="mobile" placeholder="Enter your mobile number" required="">
            </div>
          </div>
          <div class="mb-3">
            <label for="city" class="form-label">Enter your City or District<span class="text-danger">*</span></label>
            <div class="input-group">
              <span class="input-group-text"><i class="fa fa-map-marker"></i></span>
              <input type="text" class="form-control" name="city" placeholder="Enter your city or district" required=""> 
            </div>
          </div>
          <button type="submit" class="btn btn-primary w-100">Check Offers</button>
        </form>
      </div>
      <div class="modal-footer">
        <p class="text-center">
          By proceeding, you explicitly agree to TruckMitr's 
          <a href="#" target="_blank">Terms and Conditions</a>.
        </p>
      </div>
    </div>
  </div>
</div>

<!--Check offer end-->
  
  <main class="py-4 sectionShadow">
    @if(isset($productsc))
    <script>
        let productsc = @json($productsc);
    </script>
    <div class="container">
         @if (session('success'))
                            <div class="alert alert-success">
                                {{ session('success') }}
                            </div>
                        @endif
                        
        <div class="sectionHeading text-center mb-5">
          <a class="backbtn" href="{{ url()->previous() }}"><i class="fa fa-arrow-left" aria-hidden="true"></i> Back</a> </a>
          
            
        <?php $total = count($productsc);?>  
        
        <!--<?php for($i=0;$i<$total;$i++){ ?>-->
        <!--  <h1 class="pt-4"> {{get_brand_by_id($productsc[$i]['brand_id'])}} {{$productsc[$i]['Vehicle_model']}} <?php if($i<$total-1){ ?> VS <?php } ?> </h1>-->
        <!--<?php } ?>-->
        </div>
        <div class="row compare-container">
          <?php for($i=1;$i<=$total;$i++){ ?>
          <div class="col-6 col-sm-6 col-md-3 col-lg-3">
            <div class="newTruckBlock-inner sectionShadow">
              <a
                href="https://trucks.tractorjunction.com/en/tata-truck/ultra-2821t"
                title="Tata Ultra 2821.T Truck"
              >
                <div class="newTruckBlock-img">
                  <img src="{{ url('public/'.$productsc[$i-1]['images']) }}?width=466&amp;height=272" data-src="{{ url('public/'.$productsc[$i-1]['images']) }}?width=466&amp;height=272"
                    class="img-fluid"
                    alt="Tata Ultra 2821.T Truck"
                    style="height:240px;"
                  />
                </div>
              </a>
              <div class="newTruckBlock-content text-center">
                <a
                  href="https://trucks.tractorjunction.com/en/tata-truck/ultra-2821t"
                  title="Tata Ultra 2821.T Truck"
                >
                 
                   <p class="newTruckBlock-title boldfont">
                     {{$productsc[$i-1]['oem_name']}} {{$productsc[$i-1]['Vehicle_model']}}
                  </p>
                </a>
                <p class="newTruckBlock-price">₹ {{$productsc[$i-1]['Price_Range']}} - {{$productsc[$i-1]['max_price']}} </p>
                <a data-bs-toggle="modal" data-bs-target="#eicherModal"><span
                  data-title="Tata Ultra 2821.T Truck"
                  data-brand="tata"
                  data-model="ultra-2821t"
                  data-source="Grid Popup Leads"
                  title="Tata Ultra 2821.T Truck"
                  class="borderBtn newTruckBlock-btn GetOnRoadPriceForm"
                  >Check Offers</span
                >
                </a>
              </div>
            </div>
          </div>
          <?php if($i<=$total-1){ ?>
          <!--<div class="d-none d-sm-none d-md-block col-md-2 vsBlock"></div>-->
          <?php } ?>
          <?php } ?>

          
        </div>
      </div>
    </main>

    <section class="py-3">
      <div class="container">
        <div class="sectionHeading headingbar mb-4">
        
        <div class="accordion" id="accordionPanelsStayOpenExample">
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#panelsStayOpen-collapseOne"
                aria-expanded="true"
                aria-controls="panelsStayOpen-collapseOne"
              >
                Performance
              </button>
            </h2>
            <div
              id="panelsStayOpen-collapseOne"
              class="accordion-collapse collapse show"
            >
              <div class="accordion-body p-0">
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                        <p class="boldfont">Engine Capacity(cc)</p>
                    </div>
                
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Engine_capacity'] }}</p>
                        </div>
                    @endforeach
                </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Engine HP</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Engine_HP'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Engine Make</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Engine_make'] }}</p>
                        </div>
                    @endforeach
                    </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Engine Model</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Engine_model'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">MAX Engine Output</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['MAX_Engine_output'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">MAX Torque</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['MAX_Torque'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">No. of Cylinders</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['No_of_cylinders'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                
              </div>
            </div>
          </div>
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#panelsStayOpen-collapseTwo"
                aria-expanded="false"
                aria-controls="panelsStayOpen-collapseTwo"
              >
                Dimensions
              </button>
            </h2>
            <div
              id="panelsStayOpen-collapseTwo"
              class="accordion-collapse collapse"
            >
              <div class="accordion-body p-0">
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Ground Clearance(mm)</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Ground_clearance'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Min. Turning Circle Dia(mm) </p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Min_Turning_circle_dia'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Overall Height(mm)</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Overall_Height'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Overall Length(mm)</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Overall_Length'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Overall Width(mm)</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Overall_Width'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Wheel Base(mm)</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Wheel_base'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#panelsStayOpen-collapseThree"
                aria-expanded="false"
                aria-controls="panelsStayOpen-collapseThree"
              >
                Driveline
              </button>
            </h2>
            <div
              id="panelsStayOpen-collapseThree"
              class="accordion-collapse collapse"
            >
              <div class="accordion-body p-0">
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Clutch Type</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Clutch_type'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Front Axle Type</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Front_axle_Type'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Gear Box Model</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Gear_Box_Model'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">No. of Gears</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['No_of_gears'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">O.D of Clutch Lining (mm)</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['OD_of_clutch_lining'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Rear Axle Ratio</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Rear_axle_Ratio'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Type of Actuation</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Type_of_actuation'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Rear Axle Model</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Rear_axle_Model'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#panelsStayOpen-collapseFour"
                aria-expanded="false"
                aria-controls="panelsStayOpen-collapseFour"
              >
                Capacity
              </button>
            </h2>
            <div
              id="panelsStayOpen-collapseFour"
              class="accordion-collapse collapse"
            >
              <div class="accordion-body p-0">
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Diesel Exhaust Fluid (DEF) </p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Diesel_Exhaust_Fluid'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Fuel Tank Capacity</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Fuel_tank_Capacity'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Max.Permissible GVW</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Max_Permissible_GVW'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                </div>
            </div>
          </div>
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#panelsStayOpen-collapseFive"
                aria-expanded="false"
                aria-controls="panelsStayOpen-collapseFive"
              >
                Brakes
              </button>
            </h2>
            <div
              id="panelsStayOpen-collapseFive"
              class="accordion-collapse collapse"
            >
              <div class="accordion-body p-0">
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Auxiliary Braking System</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Auxiliary_Braking_System'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Brakes Type</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Brakes_type'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div><div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Parking Brake</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Parking_brake'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#panelsStayOpen-collapseSix"
                aria-expanded="false"
                aria-controls="panelsStayOpen-collapseSix"
              >
                Others
              </button>
            </h2>
            <div
              id="panelsStayOpen-collapseSix"
              class="accordion-collapse collapse"
            >
              <div class="accordion-body p-0">
                <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Battery </p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Battery'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Cabin Type</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Cabin_type'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Frame type</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Frame_type'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">No. of Tyres</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['No_of_tyres'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Standard Features</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Standard_features'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Steering Type</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Steering_type'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Suspension Type Front</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Suspension_Type_Front'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Suspension Type Rear</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Suspension_Type_Rear'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
                 <div class="compareResult-inner">
                  <div class="row">
                    <div class="col-12">
                      <p class="boldfont">Wheels</p>
                    </div>
                    @foreach($productsc as $index => $product)
                        @php
                            $colSize = 12 / count($productsc); 
                        @endphp
                        <div class="col-{{$colSize}}">
                            <p class="m-0">{{ $product['Wheels'] }}</p>
                        </div>
                    @endforeach
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      </div>
    </section>
    
    
    <script>document.addEventListener("DOMContentLoaded", function () {
    let items = document.querySelectorAll(".newTruckBlock-inner");
    let parentRow = document.querySelector(".row");

    function checkCentering() {
        let visibleItems = Array.from(items).filter(item => item.style.display !== "none");

        if (visibleItems.length === 2) {
            parentRow.classList.add("compare-container");
        } else {
            parentRow.classList.remove("compare-container");
        }
    }

    checkCentering(); // Initial check
});
</script>
    
    @endif

@include('Fronted.footer')


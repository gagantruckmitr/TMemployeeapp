@include('Fronted.header')

<style>

    .selected {
        background-color: #007bff; /* Change to your desired selected color */
        color: white; /* Change text color if needed */
    }

  .border {border: 1px solid rgba(0, 0, 0, 0.175);
  }
  .fa {padding: 0;font-size: inherit;width: inherit;text-align: center;
    text-decoration: none;margin: 0;border-radius: 0;
  }
  .lightgrey {color: lightgrey;}
.dashedBorder {border: 1px dashed blue;border-radius: 8px;
  }
.progress {width: 11rem;height: 5px;}
.carousel-control-prev,
.carousel-control-next {background-color: skyblue;border-radius: 50%;width: 35px;
    height: 35px;opacity: 0.8;top: 50%;padding: 10px;transition: opacity 0.3s;}
.carousel-control-prev-icon,
  .carousel-control-next-icon {filter: brightness(0) invert(1);}
.accordion-item {margin: 20px 0;border-radius: 10px;border: none;}
.accordion-button {background: #f4f4f4;border-radius: 10px 10px 10px 10px !important;}
.accordion-button:not(.collapsed),
.accordion-body {background: #2c6cc4;color: white;
  border-radius: 10px 10px 10px 10px !important;}
.accordion-button:not(.collapsed) {border-radius: 10px 10px 0px 0px !important;}
  .accordion-body {margin-top: -10px;border-radius: 0 0 10px 10px;}
  .accordion-button:focus {box-shadow: none;border: none;}
.cardlist.card {width: 22%;}
.text-sky-blue {color: #52add9;}
.text-blue {color: #1868b3;}
.text-gray {color: rgb(184 184 184);}
.border-blue {border-color: #1868b3;}
p {margin-bottom: 0px;}
.nav-pills .nav-link.active {background-color: transparent;color: #1868b3;
    border-bottom: 3px solid #1868b3;border-radius: 0;}
@media only screen and (max-width: 768px) {
.main-card {width: 94%;}
.cardlist.card {width: 100%;}}
@media (min-width:769px) and (max-width: 991px) {
.main-card{width: 97%;}
.cardlist.card {width: 30%;}
}
.table.performance td {border-bottom: 0;}
.btn:hover .fa{
    color: white;
}
.card-title {
  font-size: 18px;
}



</style>
 @if(isset($Trucklist))
<section class="py-lg-5">
  <div class="container">
    <div class="row gx-lg-5 justify-content-center">
      <aside class="col-lg-6 my-4 my-md-0">

    @if(isset($image) && !empty($image) && isset($image[0]))
        <!-- Main image section -->
        <div class="border rounded-4 mb-3 d-flex justify-content-center">
            <div
                data-fslightbox="mygalley"
                class="rounded-4 w-100"
                data-type="image"
            >
                <img
                    id="mainImage"
                    style="height:373px;width: 100%; margin: auto"
                    class="rounded-4 fit"
                    src="{{ url('public/'.$Trucklist->images) }}"
                />
            </div>
        </div>
        
        <!-- Thumbnail section -->
        <div class="d-flex my-4" style="overflow-x: auto; white-space: nowrap; -ms-overflow-style: none; scrollbar-width: none;">
            @foreach($image as $key => $img)
                <div
                    class="mx-2 rounded-2 item-thumb"
                    data-type="image"
                    onclick="changeMainImage('{{ url('public/'.$img->multi_image) }}')"
                >
                    <img 
                        style="height: 102px;width: 104px;" 
                        class="rounded-2" 
                        src="{{ url('public/'.$img->multi_image) }}"/>
                </div>
            @endforeach
        </div>
    @endif

</aside>

      <main class="col-lg-5 card p-3 border mx-lg-4 main-card">
        <div class="card-body">
          <div class="">
            <!--<div class="d-flex flex-row mb-3">-->
            <!--  <div class="text-warning mb-1">-->
            <!--    <i class="fa fa-star"></i>-->
            <!--    <i class="fa fa-star"></i>-->
            <!--    <i class="fa fa-star"></i>-->
            <!--    <i class="fa fa-star"></i>-->
            <!--    <i class="fa fa-star lightgrey"></i>-->
            <!--  </div>-->
            <!--  <span class="text-muted ms-2">(20 Reviews)</span>-->
            <!--</div>-->
            <!--<p>Brand:- {{$Trucklist->name}}</p>-->
            <h4 class="title text-dark">{{$Trucklist->oem_name}} - {{$Trucklist->Vehicle_model}}</h4>

            <?php echo substr($Trucklist->Description, 0, 200); ?>...
            <div
              class="btn-toolbar my-4 gap-3"
              role="toolbar"
              aria-label="Toolbar with button groups"
            >
              <div class="btn-group" role="group" aria-label="Second group">
                <button
                  type="button"
                  class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue px-4"
                >
                  Engine Capacity: {{$Trucklist->Engine_capacity}}
                </button>
              </div>
              <div class="btn-group" role="group" aria-label="Second group">
                <button
                  type="button"
                  class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue px-4"
                >
                  Fuel Type: {{$Trucklist->fule_type}}
                </button>
              </div>
              <div class="btn-group" role="group" aria-label="Third group">
                <button
                  type="button"
                  class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue px-4"
                >
                  Engine HP:{{$Trucklist->Engine_HP}}
                </button>
              </div>
              
              <div class="btn-group" role="group" aria-label="Third group">
                <button
                  type="button"
                  class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue px-4"
                >
                 Cylinders:{{$Trucklist->No_of_cylinders}}
                </button>
              </div>
              
            </div>
            <hr class="my-4" />

            <div class="row mb-4 d-flex">
              <div class="col-md-4 col-6 flex-grow-1">
                <p class="mb-2 d-block text-secondary">On Zero Down Payment</p>
                <span
                  ><strong class="text-blue fs-6"
                    >₹ 24,000/month</strong
                  ></span
                >
                <a
                  href="#"
                  class="fs-6 text-sky-blue mt-4 mb-2 text-decoration-none d-block" data-bs-toggle="modal" data-bs-target="#eicherModal"
                  ><p>CHECK ELIGIBILITY ⟶</p></a
                >
              </div>
              <div class="col-md-4 col-6 mb-3 flex-grow-1">
                <p class="mb-2 d-block text-secondary">Ex Showroom Price</p>
                <span
                  ><strong class="fs-6">   
                   ₹{{$Trucklist->Price_Range}} - {{$Trucklist->max_price}} Lakh*</strong
                  ></span
                >
                <a
                  href="#"
                  class="fs-6 text-sky-blue mt-4 mb-2 text-decoration-none d-block" data-bs-toggle="modal" data-bs-target="#eicherModal"
                  ><p>UNDERSTAND PRICE ⟶</p></a
                >
              </div>
            </div>
            <div class="d-flex">
              <!--<a href="#" class="btn btn-light shadow-0 rounded-pill">-->
              <!--  <i class="fa fa-share-alt"></i>-->
              <!--</a>-->
              <a href="#" class="btn btn-primary shadow-0 flex-grow-1 mx-2" data-bs-toggle="modal" data-bs-target="#eicherModal">
                Check Offers</a
>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</section>

<section class="py-4">
  <div class="container">
    <div class="row gx-4">
      <div class="col-lg-8 mb-4">
        <div class="card p-3 border">
          <div class="card-body">
            <h4 class="title text-dark">Specifications & Features</h4>

            <ul
              class="nav nav-pills my-4 overflow-x-scroll flex-nowrap border-bottom" style="-ms-overflow-style: none; scrollbar-width: none;"
              id="pills-tab"
              role="tablist"
            >
              <li class="nav-item" role="presentation">
                <button
                  class="nav-link active"
                  id="pills-performance-tab"
                  data-bs-toggle="pill"
                  data-bs-target="#pills-performance"
                  type="button"
                  role="tab"
                  aria-controls="pills-performance"
                  aria-selected="true"
                  style = "width: max-content;"
                >
                  Performance
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button
                  class="nav-link"
                  id="pills-dimensions-tab"
                  data-bs-toggle="pill"
                  data-bs-target="#pills-dimensions"
                  type="button"
                  role="tab"
                  aria-controls="pills-dimensions"
                  aria-selected="false"
                  style = "width: max-content;"
                >
                  Dimensions
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button
                  class="nav-link"
                  id="pills-suspension-tab"
                  data-bs-toggle="pill"
                  data-bs-target="#pills-suspension"
                  type="button"
                  role="tab"
                  aria-controls="pills-suspension"
                  aria-selected="false"
                  style = "width: max-content;"
                >
                  Driveline
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button
                  class="nav-link"
                  id="pills-transmission-tab"
                  data-bs-toggle="pill"
                  data-bs-target="#pills-transmission"
                  type="button"
                  role="tab"
                  aria-controls="pills-transmission"
                  aria-selected="false"
                  style = "width: max-content;"
                >
                  Capacity
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button
                  class="nav-link"
                  id="pills-cabin-tab"
                  data-bs-toggle="pill"
                  data-bs-target="#pills-cabin"
                  type="button"
                  role="tab"
                  aria-controls="pills-cabin"
                  aria-selected="false"
                  style = "width: max-content;"
                >
                  Brakes
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button
                  class="nav-link"
                  id="pills-tyre-tab"
                  data-bs-toggle="pill"
                  data-bs-target="#pills-tyre"
                  type="button"
                  role="tab"
                  aria-controls="pills-tyre"
                  aria-selected="false"
                  style = "width: max-content;"
                >
                  Others
                </button>
              </li>
            </ul>
            <div class="tab-content" id="pills-tabContent">
              <div
                class="tab-pane fade show active"
                id="pills-performance"
                role="tabpanel"
                aria-labelledby="pills-performance-tab"
                tabindex="0"
              >
                <table class="table performance">
                  <tbody>
                    <tr>
                      <td class="text-muted"><p><strong>Engine Capacity(cc)</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Engine_capacity}}</p>
                      </td>
                      <td class="text-muted"><p><strong>Engine HP</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Engine_HP}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Engine Make</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Engine_make}}</p>
                      </td>
                      <td class="text-muted"><p><strong>Engine Model</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Engine_model}}</p></strong>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted">
                        <p> <strong>MAX Engine Output </strong></p>
                        
                      </td>
                      <td>
                       <p>{{$Trucklist->MAX_Engine_output}}</p>
                      </td>
                      <td class="text-muted"><p> <strong>MAX Torque </strong></p></td>
                      <td>
                        <p>{{$Trucklist->MAX_Torque}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p> <strong>No. of Cylinders </strong></p></td>
                      <td>
                        <p>{{$Trucklist->No_of_cylinders}}</p>
                      </td>
                    </tr>
                   
                  </tbody>
                </table>
              </div>
              <div
                class="tab-pane fade"
                id="pills-dimensions"
                role="tabpanel"
                aria-labelledby="pills-dimensions-tab"
                tabindex="0"
              >
                <table class="table performance">
                  <tbody>
                    <tr>
                      <td class="text-muted"><p><strong>Ground Clearance(mm)</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Ground_clearance}}</p>
                      </td>
                      <td class="text-muted"><p> <strong>Min. Turning Circle Dia(mm) </strong></p></td>
                      <td>
                       <p>{{$Trucklist->Min_Turning_circle_dia}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Overall Height(mm)</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Overall_Height}}</p>
                      </td>
                      <td class="text-muted"><p> <strong>Overall Length(mm) </strong></p></td>
                      <td>
                       <p>{{$Trucklist->Overall_Length}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted">
                        <p><strong>Overall Width(mm)</strong></p>
                        
                      </td>
                      <td>
                        <p>{{$Trucklist->Overall_Width}}</p>
                      </td>
                     
                    </tr>
                    <tr>
                      <td class="text-muted">
                        <p><strong>Wheel Base(mm)</strong></p>
                        
                      </td>
                      <td>
                        <p>{{$Trucklist->Wheel_base}}</p>
                      </td>
                     
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                class="tab-pane fade"
                id="pills-suspension"
                role="tabpanel"
                aria-labelledby="pills-suspension-tab"
                tabindex="0"
              >
                <table class="table performance">
                  <tbody>
                    <tr>
                      <td class="text-muted"><p> <strong>Clutch Type  </strong></p></td>
                      <td>
                       <p>{{$Trucklist->Clutch_type}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>Front Axle Type</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Front_axle_Type}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Gear Box Model</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Gear_Box_Model}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>No. of Gears</strong></p></td>
                      <td>
                        <p>{{$Trucklist->No_of_gears}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p> <strong>O.D of Clutch Lining (mm) </strong> </p></td>
                     <td>
                       <p>{{$Trucklist->OD_of_clutch_lining}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Rear Axle Model</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Rear_axle_Model}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>Rear Axle Ratio</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Rear_axle_Ratio}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p> <strong>Type of Actuation </strong></p></td>
                      <td>
                       <p>{{$Trucklist->Type_of_actuation}}</p>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                class="tab-pane fade"
                id="pills-transmission"
                role="tabpanel"
                aria-labelledby="pills-transmission-tab"
                tabindex="0"
              >
               <table class="table performance">
                  <tbody>
                    <tr>
                      <td class="text-muted"><p><strong>Diesel Exhaust Fluid (DEF)</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Diesel_Exhaust_Fluid}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>Fuel Tank Capacity</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Fuel_tank_Capacity}}</p>
                      </td>
                    </tr>
                    <tr>
                       <td class="text-muted"><p><strong>Max.Permissible GVW</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Max_Permissible_GVW}}</p>
                      </td> 
                    </tr>
                   
                  </tbody>
                </table>
              </div>
              <div
                class="tab-pane fade"
                id="pills-cabin"
                role="tabpanel"
                aria-labelledby="pills-cabin-tab"
                tabindex="0"
              >
                <table class="table performance">
                  <tbody>
                    <tr>
                      <td class="text-muted breaks"><p><strong>Auxiliary Braking System </strong></p></td>
                      <td>
                        <p>{{$Trucklist->Auxiliary_Braking_System}}</p>
                      </td>
                      </tr>
                      <tr>
                       <td class="text-muted breaks"><p><strong>Brakes Type</strong></p></td> 
                      <td>
                       <p>{{$Trucklist->Brakes_type}}</p>
                      </td>
                      </tr>
                    
                    <tr>
                      <td class="text-muted breaks"><p><strong>Parking Brake</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Parking_brake}}</p>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                class="tab-pane fade"
                id="pills-tyre"
                role="tabpanel"
                aria-labelledby="pills-tyre-tab"
                tabindex="0"
              >
                 <table class="table performance">
                  <tbody>
                    <tr>
                      <td class="text-muted"><p><strong>Battery</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Battery}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>Cabin Type</strong></p></td>
                      <td>
                    <p>{{$Trucklist->Cabin_type}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Frame type</strong></p></td>
                      <td>
                       <p>{{$Trucklist->Frame_type}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>No. of Tyres</strong></p></td>
                      <td>
                        <p>{{$Trucklist->No_of_tyres}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Standard Features</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Standard_features}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>Steering Type</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Steering_type}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Suspension Type Front </strong></p></td>
                      <td>
                        <p>{{$Trucklist->Suspension_Type_Front}}</p>
                      </td>
                      </tr>
                      <tr>
                      <td class="text-muted"><p><strong>Suspension Type Rear</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Suspension_Type_Rear}}</p>
                      </td>
                    </tr>
                    <tr>
                      <td class="text-muted"><p><strong>Wheels</strong></p></td>
                      <td>
                        <p>{{$Trucklist->Wheels}}</p>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
     @endif
        <div class="card p-3 mt-4 border">
          <div class="card-body">
            <h4 class="title text-dark">{{$Trucklist->oem_name}} - {{$Trucklist->Vehicle_model}} Description</h4>
            <p class="my-3">
               {{$Trucklist->Description}}
            </p>
           
          </div>
        </div>

        <!--<div class="card p-3 mt-4 border">-->
        <!--  <div class="card-body">-->
        <!--    <h4 class="title text-dark">{{$Trucklist->oem_name}} - {{$Trucklist->Vehicle_model}} Price List (Variants)</h4>-->
        <!--    <div-->
        <!--      class="d-flex flex-wrap dashedBorder border-blue p-4 justify-content-between my-4 gap-4"-->
        <!--    >-->
        <!--      <div class="">-->
        <!--        <h5>Tata Signa 1918.K 3580/10.5m3 Box</h5>-->
        <!--        <p>5005 CC, Diesel, GVW 18600 kg</p>-->
        <!--      </div>-->
        <!--      <div class="">-->
        <!--        <div><strong>Rs. 33.43 - Rs. 37.43 Lakh</strong></div>-->
        <!--        <a href="#" class="text-blue text-decoration-none"-->
        <!--          >View on road price*</a-->
        <!--        >-->
        <!--      </div>-->
        <!--      <div class="d-flex align-items-center">-->
        <!--        <button type="button" class="btn btn-primary shadow-0 flex-grow-1 mx-2" data-bs-toggle="modal" data-bs-target="#eicherModal">-->
        <!--          Check Offers</button>-->
        <!--      </div>-->
        <!--    </div>-->
        <!--    <div-->
        <!--      class="d-flex flex-wrap dashedBorder border-blue p-4 justify-content-between my-4 gap-4"-->
        <!--    >-->
        <!--      <div class="">-->
        <!--        <h5>Tata Signa 1918.K 3580/10.5m3 Box</h5>-->
        <!--        <p>5005 CC, Diesel, GVW 18600 kg</p>-->
        <!--      </div>-->
        <!--      <div class="">-->
        <!--        <div><strong>Rs. 33.43 - Rs. 37.43 Lakh</strong></div>-->
        <!--        <a href="#" class="text-blue text-decoration-none"-->
        <!--          >View on road price*</a-->
        <!--        >-->
        <!--      </div>-->
        <!--      <div class="d-flex align-items-center">-->
        <!--        <button type="button" class="btn btn-primary shadow-0 flex-grow-1 mx-2" data-bs-toggle="modal" data-bs-target="#eicherModal">-->
        <!--          Check Offers</button>-->
        <!--      </div>-->
        <!--    </div>-->
        <!--  </div>-->
        <!--</div>-->

        <!--<div class="card p-3 mt-4 border">-->
        <!--  <div class="card-body">-->
        <!--    <h4 class="title text-dark">{{$Trucklist->oem_name}} - {{$Trucklist->Vehicle_model}} Reviews</h4>-->
        <!--    <div class="d-flex flex-wrap justify-content-between my-4 gap-4">-->
        <!--      <div class="">-->
        <!--        <div class="d-flex flex-row align-items-center gap-2">-->
        <!--          <h3 class="fs-1"><strong>4.3</strong></h3>-->
        <!--          <h4 class="text-warning">-->
        <!--            <i class="fa fa-star pl-1"></i>-->
        <!--          </h4>-->
        <!--        </div>-->
        <!--        <p>-->
        <!--          Based on <br />-->
        <!--          4 User Reviews-->
        <!--        </p>-->
        <!--      </div>-->
        <!--      <div class="">-->
        <!--        <div class="d-flex align-items-center gap-3">-->
        <!--          <p class="text-gray">Performance</p>-->
        <!--          <div-->
        <!--            class="progress"-->
        <!--            role="progressbar"-->
        <!--            aria-label="Basic example"-->
        <!--            aria-valuenow="25"-->
        <!--            aria-valuemin="0"-->
        <!--            aria-valuemax="100"-->
        <!--          >-->
        <!--            <div class="progress-bar" style="width: 80%"></div>-->
        <!--          </div>-->
        <!--          <p class="text-gray">4</p>-->
        <!--        </div>-->

        <!--        <div class="d-flex align-items-center gap-3">-->
        <!--          <p class="text-gray">Maintenance</p>-->
        <!--          <div-->
        <!--            class="progress"-->
        <!--            role="progressbar"-->
        <!--            aria-label="Basic example"-->
        <!--            aria-valuenow="25"-->
        <!--            aria-valuemin="0"-->
        <!--            aria-valuemax="100"-->
        <!--          >-->
        <!--            <div class="progress-bar" style="width: 80%"></div>-->
        <!--          </div>-->
        <!--          <p class="text-gray">4</p>-->
        <!--        </div>-->

        <!--        <div class="d-flex align-items-center gap-3">-->
        <!--          <p class="text-gray">Design & Build</p>-->
        <!--          <div-->
        <!--            class="progress"-->
        <!--            role="progressbar"-->
        <!--            aria-label="Basic example"-->
        <!--            aria-valuenow="25"-->
        <!--            aria-valuemin="0"-->
        <!--            aria-valuemax="100"-->
        <!--          >-->
        <!--            <div class="progress-bar" style="width: 80%"></div>-->
        <!--          </div>-->
        <!--          <p class="text-gray">4</p>-->
        <!--        </div>-->
        <!--      </div>-->
        <!--      <div class="d-flex align-items-center">-->
        <!--        <a href="#" class="btn btn-primary shadow-0 flex-grow-1 px-4">-->
        <!--          Write a Review</a-->
        <!--        >-->
        <!--      </div>-->
        <!--    </div>-->
        <!--    <div-->
        <!--      id="carouselExampleControls"-->
        <!--      class="carousel carousel-dark slide"-->
        <!--      data-bs-ride="carousel"-->
        <!--    >-->
        <!--      <div class="carousel-inner">-->
        <!--        <div class="carousel-item active">-->
        <!--          <div-->
        <!--            class="card-wrapper container-sm d-flex justify-content-around"-->
        <!--          >-->
        <!--            <div class="card p-0 m-md-3 border shadow-none">-->
        <!--              <div class="card-body text-center p-3 p-md-5">-->
        <!--                <h4 class="text-warning mb-1">-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                </h4>-->
        <!--                <p class="text-muted py-4">-->
        <!--                  "Lorem Ipsum is simply dummy text of the printing and-->
        <!--                  typesetting industry. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy"-->
        <!--                </p>-->
        <!--                <div class="d-flex text-start justify-content-center">-->
                          
        <!--                  <div-->
        <!--                    class="d-flex flex-column justify-content-center text-start mx-3"-->
        <!--                  >-->
        <!--                    <h5 class="mb-0">Ramesh Kumar</h5>-->
        <!--                    <p>Truck Driver</p>-->
        <!--                  </div>-->
        <!--                </div>-->
        <!--              </div>-->
        <!--            </div>-->
        <!--            <div-->
        <!--              class="card p-0 m-md-3 border shadow-none d-none d-md-block"-->
        <!--            >-->
        <!--              <div class="card-body text-center p-3 p-md-5">-->
        <!--                <h4 class="text-warning mb-1">-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                </h4>-->
        <!--                <p class="text-muted py-4">-->
        <!--                  "Lorem Ipsum is simply dummy text of the printing and-->
        <!--                  typesetting industry. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy"-->
        <!--                </p>-->
        <!--                <div class="d-flex text-start justify-content-center">-->
                          
        <!--                  <div-->
        <!--                    class="d-flex flex-column justify-content-center text-start mx-3"-->
        <!--                  >-->
        <!--                    <h5 class="mb-0">Ramesh Kumar</h5>-->
        <!--                    <p>Truck Driver</p>-->
        <!--                  </div>-->
        <!--                </div>-->
        <!--              </div>-->
        <!--            </div>-->
        <!--          </div>-->
        <!--        </div>-->
        <!--        <div class="carousel-item">-->
        <!--          <div-->
        <!--            class="card-wrapper container-sm d-flex justify-content-around"-->
        <!--          >-->
        <!--            <div class="card p-0 m-md-3 border shadow-none">-->
        <!--              <div class="card-body text-center p-3 p-md-5">-->
        <!--                <h4 class="text-warning mb-1">-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                </h4>-->
        <!--                <p class="text-muted py-4">-->
        <!--                  "Lorem Ipsum is simply dummy text of the printing and-->
        <!--                  typesetting industry. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy"-->
        <!--                </p>-->
        <!--                <div class="d-flex text-start justify-content-center">-->
                          
        <!--                  <div-->
        <!--                    class="d-flex flex-column justify-content-center text-start mx-3"-->
        <!--                  >-->
        <!--                    <h5 class="mb-0">Ramesh Kumar</h5>-->
        <!--                    <p>Truck Driver</p>-->
        <!--                  </div>-->
        <!--                </div>-->
        <!--              </div>-->
        <!--            </div>-->
        <!--            <div-->
        <!--              class="card p-0 m-md-3 border shadow-none d-none d-md-block"-->
        <!--            >-->
        <!--              <div class="card-body text-center p-3 p-md-5">-->
        <!--                <h4 class="text-warning mb-1">-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                  <i class="fa fa-star"></i>-->
        <!--                </h4>-->
        <!--                <p class="text-muted py-4">-->
        <!--                  "Lorem Ipsum is simply dummy text of the printing and-->
        <!--                  typesetting industry. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy. Lorem Ipsum has been the-->
        <!--                  industry's standard dummy"-->
        <!--                </p>-->
        <!--                <div class="d-flex text-start justify-content-center">-->
                          
        <!--                  <div-->
        <!--                    class="d-flex flex-column justify-content-center text-start mx-3"-->
        <!--                  >-->
        <!--                    <h5 class="mb-0">Ramesh Kumar</h5>-->
        <!--                    <p>Truck Driver</p>-->
        <!--                  </div>-->
        <!--                </div>-->
        <!--              </div>-->
        <!--            </div>-->
        <!--          </div>-->
        <!--        </div>-->
        <!--        <button-->
        <!--          class="carousel-control-prev"-->
        <!--          type="button"-->
        <!--          data-bs-target="#carouselExampleControls"-->
        <!--          data-bs-slide="prev"-->
        <!--        >-->
        <!--          <span-->
        <!--            class="carousel-control-prev-icon"-->
        <!--            aria-hidden="true"-->
        <!--          ></span>-->
        <!--          <span class="visually-hidden">Previous</span>-->
        <!--        </button>-->
        <!--        <button-->
        <!--          class="carousel-control-next"-->
        <!--          type="button"-->
        <!--          data-bs-target="#carouselExampleControls"-->
        <!--          data-bs-slide="next"-->
        <!--        >-->
        <!--          <span-->
        <!--            class="carousel-control-next-icon"-->
        <!--            aria-hidden="true"-->
        <!--          ></span>-->
        <!--          <span class="visually-hidden">Next</span>-->
        <!--        </button>-->
        <!--      </div>-->
        <!--    </div>-->
        <!--  </div>-->
        <!--</div>-->
      </div>

      <!-- Sidebar -->
      <div class="col-lg-4">
        <!--<div class="card p-3 border mx-lg-4">-->
        <!--  <div class="card-body">-->
        <!--    <h4 class="card-title">Calculate EMI</h4>-->
        <!--    <p>Your monthly EMI</p>-->
        <!--    <span class="text-blue fs-5"-->
        <!--      ><strong>Rs. 24,000/month</strong></span-->
        <!--    >-->
        <!--    <p class="my-3">Interest calculated at 9.8% for 48 months</p>-->
        <!--    <button-->
        <!--      type="button"-->
        <!--      class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue" data-bs-toggle="modal" data-bs-target="#eicherModal"-->
        <!--    >-->
        <!--      View EMI Offers-->
        <!--    </button>-->
        <!--  </div>-->
        <!--</div>-->

        <div class="card p-3 border mx-lg-4">
          <div class="card-body">
            <h3 class="card-title">{{$Trucklist->Vehicle_model}} Brochure</h3>
            <p class="my-3">
              Download brochure for detailed information of specs, features &
              prices.
            </p>
            <a href="{{url('public/'.$Trucklist->brochure_pdf)}}" download class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue">
              Download Brochure
            </a>   

          </div>
        </div>

        <div class="card p-3 mt-4 border mx-lg-4 btn-primary text-white">
          <div class="card-body">
            <h4 class="card-title">Contact Us</h4>
            <p class="mt-3 mb-5">
              Got questions or feedback? We're always ready to assist you. Reach
              out to our dedicated team via email or phone, and let's connect to
              ensure your needs are met!
            </p>
            <a href="/contact"
              class="btn btn-outline-light col-12 rounded-pill text-white"
            >
              Contact Us
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!--<section class="my-4">
  <div class="container">
    <div class="row gx-lg-5">
      <div class="col-12 col-lg-8">
        <h4 class="mb-4">Frequently Asked Questions on Tata Signa</h4>
        <div class="accordion" id="accordionExample">
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button
                class="accordion-button"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#collapseOne"
                aria-expanded="true"
                aria-controls="collapseOne"
              >
               Description
              </button>
            </h2>
            <div
              id="collapseOne"
              class="accordion-collapse collapse show"
              data-bs-parent="#accordionExample"
            >
              <p class="accordion-body">
               {{$Trucklist->Description}}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>-->

<section class="my-4 mb-5">
  <div class="container">
    <div class="row gx-lg-5">
      <div class="col-12">
        <div class="d-flex justify-content-between">
          <h4 class="mb-4">For Top Comparisons <a href="{{url('compares')}}">Click Here</a></h4>
          
        </div>
        <div class="d-flex gap-4 flex-wrap">
            
          @if(isset($Truck))
            @foreach($Truck as $value)
            <div class="cardlist card p-0 rounded-4 d-flex flex-column">
            <img style="height:200px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>
           
            <div class="card-body text-center d-flex flex-column">
                
                <h4 class="" style="font-size: 21px; line-height: 17px;">{{$value->oem_name}}</h4>
                         <h5 class="card-title">{{ Str::limit($value->Vehicle_model, 20) }}</h5>
                <p class="card-text">₹{{$value->Price_Range}} - {{$value->max_price}} Lakh*</p>

                <div class="d-flex my-3 mb-4">
                <div class="col-6">
                    <p class="text-gray">Wheel</p>
                    <p class="text-blue">{{$value->Wheels}}</p>
                </div>
                <div class="col-6 border-start">
                    <p class="text-gray">ENGINE</p>
                    <p class="text-blue">{{$value->Engine_HP}}</p>
                </div>
                </div>
               <a href="{{url('compares')}}"> <label class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue mt-auto">
                    <!--<input class="compare-checkbox" value="{{$value->slug}}" type="checkbox">-->
                    Compare
                </label></a>

            </div>
            </div>
               @endforeach
            @endif
          
        </div>
      </div>
    </div>
  </div>
  
  
  
  
</section>

<section class="my-4 mb-5">
  <div class="container">
    <div class="row gx-lg-5">
      <div class="col-12">
        <div class="d-flex justify-content-between">
          <h4 class="mb-4">Recommended Trucks</h4>
          
        </div>
        <div class="d-flex gap-4 flex-wrap">
            
          @if(isset($Truck))
            @foreach($Truck as $value)
            <div class="cardlist card p-0 rounded-4">
            <img style="height:200px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>
           
            <div class="card-body text-center d-flex flex-column">
               
                <h4 class="" style="font-size: 21px; line-height: 17px;">{{$value->oem_name}}</h4>
                  <h5 class="card-title">{{ Str::limit($value->Vehicle_model, 20) }}</h5>
                <p class="card-text">₹{{$value->Price_Range}} - {{$value->max_price}} Lakh*</p>

                <div class="d-flex my-3 mb-4">
                <div class="col-6">
                    <p class="text-gray">Wheel</p>
                    <p class="text-blue">{{$value->Wheels}}</p>
                </div>
                <div class="col-6 border-start">
                    <p class="text-gray">ENGINE</p>
                    <p class="text-blue">{{$value->Engine_HP}}</p>
                </div>
                </div>
                <a class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue d-flex justify-content-center gap-3 align-items-center mt-auto" href="{{url('product-details')}}/{{$value->slug}}">Check Offers <i class="fa fa-long-arrow-right w-auto"></i></a>
            </div>
            </div>
               @endforeach
            @endif
          
        </div>
      </div>
    </div>
  </div>
</section>



<section class="my-4 mb-5">
  <div class="container">
    <div class="row gx-lg-5">
      <div class="col-12">
        <div class="d-flex justify-content-between">
          <h4 class="mb-4">Newly Launched Trucks</h4>
        </div>
        <div class="d-flex gap-4 flex-wrap">
            
           @if(isset($TruckNew))
            @foreach($TruckNew as $value)
            <div class="cardlist card p-0 rounded-4">
            <img style="height:200px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>
           
            <div class="card-body text-center d-flex flex-column">
                
              <h4 class="" style="font-size: 21px; line-height: 17px;">{{$value->oem_name}}</h4>
              <h5 class="card-title">{{ Str::limit($value->Vehicle_model, 20) }}</h5>
                <p class="card-text">₹{{$value->Price_Range}} - {{$value->max_price}} Lakh*</p>

                <div class="d-flex my-3 mb-4">
                <div class="col-6">
                    <p class="text-gray">Wheel</p>
                    <p class="text-blue">{{$value->Wheels}}</p>
                </div>
                <div class="col-6 border-start">
                    <p class="text-gray">ENGINE</p>
                    <p class="text-blue">{{$value->Engine_HP}}</p>
                </div>
                </div>
                <a class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue d-flex justify-content-center gap-3 align-items-center mt-auto" href="{{url('product-details')}}/{{$value->slug}}">Check Offers <i class="fa fa-long-arrow-right w-auto"></i></a>
            </div>
            
          
            </div>
               @endforeach
            @endif
         
        </div>
      </div>
    </div>
  </div>
</section>
<script>
    const checkboxes = document.querySelectorAll('.compare-checkbox');
    const labels = document.querySelectorAll('label');

    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', (event) => {
            const label = checkbox.closest('label');
            
            // Toggle 'selected' class based on checkbox state
            if (checkbox.checked) {
                label.classList.add('selected');
            } else {
                label.classList.remove('selected');
            }

            // Get checked values
            const checkedValues = Array.from(checkboxes)
                .filter(checkbox => checkbox.checked)
                .map(checkbox => checkbox.value);

            const checkedCount = checkedValues.length;
            console.log(checkedValues);

            if (checkedCount === 2) {
                const url = `https://truck.rupanchhap.shop/compare/${checkedValues.join('/')}`;
                console.log("Redirecting to:", url);
                window.location.href = url;
            }
        });
    });
</script>
<!--<section class="my-4 mb-5">
  <div class="container">
    <div class="row gx-lg-5">
      <div class="col-12">
        <div class="d-flex justify-content-between">
          <h4 class="mb-4">Popular Comparisons Truck List</h4>
          
        </div>
        <div class="d-flex gap-4 flex-wrap">
            
          @if(isset($Truck))
            @foreach($Truck as $value)
            <div class="cardlist card p-0 rounded-4">
            <img style="height:200px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>
           
            <div class="card-body text-center">
                <h5 class="card-title">
                <strong>{{$value->oem_name}}</strong>
                </h5>
                <p class="card-text">{{$value->Price_Range}}</p>

                <div class="d-flex my-3 mb-4">
                <div class="col-6">
                    <p class="text-gray">Wheel</p>
                    <p class="text-blue">{{$value->Wheels}}</p>
                </div>
                <div class="col-6 border-start">
                    <p class="text-gray">ENGINE</p>
                    <p class="text-blue">{{$value->Engine_HP}}</p>
                </div>
                </div>
                <a class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue" href="{{url('product-details')}}/{{$value->slug}}">Check Offers <i class="fa fa-long-arrow-right"></i></a>
            </div>
            </div>
               @endforeach
            @endif
          
        </div>
      </div>
    </div>
  </div>
</section>-->



<!--<section class="my-4 mb-5">
  <div class="container">
    <div class="row gx-lg-5">
      <div class="col-12">
        <div class="d-flex justify-content-between">
          <h4 class="mb-4">Newly Launched Trucks</h4>
        </div>
        <div class="d-flex gap-4 flex-wrap">
            
           @if(isset($TruckNew))
            @foreach($TruckNew as $value)
            <div class="cardlist card p-0 rounded-4">
            <img style="height:200px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>
           
            <div class="card-body text-center">
                <h5 class="card-title">
                <strong>{{$value->oem_name}}</strong>
                </h5>
                <p class="card-text">{{$value->Price_Range}}</p>

                <div class="d-flex my-3 mb-4">
                <div class="col-6">
                    <p class="text-gray">Wheel</p>
                    <p class="text-blue">{{$value->Wheels}}</p>
                </div>
                <div class="col-6 border-start">
                    <p class="text-gray">ENGINE</p>
                    <p class="text-blue">{{$value->Engine_HP}}</p>
                </div>
                </div>
                <a class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue" href="{{url('product-details')}}/{{$value->slug}}">Check Offers <i class="fa fa-long-arrow-right"></i></a>
            </div>
            
          
            </div>
               @endforeach
            @endif
         
        </div>
      </div>
    </div>
  </div>
</section>-->

<!-- Check Offers Bootstrap Modal -->

<div class="modal fade" id="eicherModal" tabindex="-1" aria-labelledby="eicherModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="eicherModalLabel">{{$Trucklist->oem_name}} - {{$Trucklist->Vehicle_model}}</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      @if (session('success'))
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        {{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
@endif

      <div class="modal-body">
       <form method="POST" action="{{url('track_submit')}}">
                                 @csrf
          <div class="row">
            <div class="col-md-6 mb-3">
              <label for="name" class="form-label">Name<span class="text-danger">*</span></label>
              <input type="text" class="form-control" name="names" id="name" placeholder="Enter your name" required="">
            </div>
            <div class="col-md-6 mb-3">
              <label for="mobile" class="form-label">Mobile Number<span class="text-danger">*</span></label>
              <input type="tel" class="form-control" name="mobile" id="mobile" placeholder="Enter your mobile number"  maxlength="10" required="">
            </div>
          </div>
          <div class="mb-3">
            <label for="city" class="form-label">Enter your City or District<span class="text-danger">*</span></label>
            <div class="input-group">
              <span class="input-group-text"><i class="fa fa-map-marker"></i></span>
              <input type="text" class="form-control" name="city" id="city" placeholder="Enter your city or district" required=""> 
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

<script>
// JavaScript function to change the main image on thumbnail click
function changeMainImage(imageSrc) {
    var mainImage = document.getElementById('mainImage');
    mainImage.src = imageSrc;
}
</script>


@include('Fronted.footer')
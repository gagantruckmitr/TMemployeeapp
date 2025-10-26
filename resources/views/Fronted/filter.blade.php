@include('Fronted.header')
<link href="{{url('public/front/assets/css/filter.css')}}" rel="stylesheet">
<style>

#pagination {
  justify-content: center;
  margin-top: 2rem;
  position: absolute;
  bottom: 564px;
  z-index: 999999999999999 !important;
  margin-bottom: 120px !important;
}

#pagination a {
  width: auto;
  padding: 5px 10px;
  margin: 2px;
  text-decoration: none;
  background: #3F6AC2;
  border-radius: 8px;
  color: white;
  text-align: center;
}

    /* Hide the accordion headers on mobile and show the button */
@media (max-width: 767px) {
    .filters-btn {
        display: block;
        width: 100%;
        text-align: left;
        background: white;
        font-size: 16px;
        cursor: pointer;
    }
.accordion-collapse {
    transition: height 0.3s ease;
}

#pagination {
  justify-content: center;
  margin-top: 2rem;
  position: absolute;
  bottom: 875px;
  z-index: 999999999999999 !important;
  margin-bottom: 120px !important;
}


.basic {
  width: 134px !important;
  border-radius: 21px;
}


.dropdown{
     width: 134px !important;
  border-radius: 21px;
}

}

.hght {
  height: 100vh;
  overflow: scroll;
}

.form-check-label {
  margin-left: 10px;
}
.sorts {
  padding: 7px;
  border: 1px solid #000;
  background: transparent;
  border-radius:50px;
}

select {
    appearance: auto; /* Ensures default dropdown styles */
    -webkit-appearance: auto; /* Safari support */
    -moz-appearance: auto; /* Firefox support */
    background-image: url('data:image/svg+xml;charset=UTF-8,%3Csvg ... %3C/svg%3E'); /* Custom dropdown icon */
    background-repeat: no-repeat;
    background-position: right 10px center;
    padding-right: 30px;
}


.basic {
  width: 170px !important;
  border-radius: 21px;
}


.dropdown{
     width: 170px;
  border-radius: 21px;
}


.form-control {
  color: var(--bs-body-color);
  -webkit-appearance: auto !important;
  -moz-appearance: auto !important;
  appearance: auto;
 
}



</style>
<main class="py-5 bg-fltr">
    <div class="container">
    <div class="row">
        <div class="col-12 col-md-6">
        <h2 class="text-white fs-1">
            Buying your dream truck? <br />
            Check Now!
        </h2>
        <div class="d-flex text-white gap-2 my-5">
            <div>Home</div>
            <span> » </span>
            <div>Trucks</div>
        </div>
        <form method="post">
            @csrf
        <div class="bg-white rounded-pill row py-2">
            <div class="col-4 mb-width-fltr d-flex">
               <div style="padding-left: 30px;" class="form-group">
                    <!--<label style="margin-bottom: 11px;" for="exampleFormControlInput1">Select Brand</label>-->
                    <select style="background-color:white; width:auto;" id="brand" name="brand" class="form-control  basic">
						<option selected>Select Brand</option>
						@if(isset($Brand))
                         @foreach($Brand as $value)
					    <option value="{{ $value->id }}">{{ $value->name }}</option>
					    @endforeach
                        @endif
					</select>
				</div>
            </div>
            
            <div class="col-4 mb-width-fltr border-start d-flex justify-content-center">
            <div style="" class="dropdown">
                 <select name="model" id="model" class="form-control citydata" required>
						<option>Select Model</option>										 
						<option> Model 1</option>										 
						<option> Model 2</option>										 
				</select>
            </div>
            </div>
            
            <div class="col-4 mb-wdth100">
            <button
                type="button" onclick="get_slug()" value="search" style="margin-top:;" 
                class="btn btn-primary col-12 rounded-pill"
            >
                Search
            </button>
            </div>
        </div>
        </form>
        </div>
    </div>
    </div>
</main>

<section>
    <div class="container">
    <div class="row">
        <div class="col-12">
        <div class="card p-3 mt-4 border">
            <div class="card-body">
            <h4 class="title text-dark">Explore latest trucks in 2025</h4>
            <p class="my-3">
              TruckMitr is your go-to platform for exploring and selecting trucks from various OEMs. Our platform offers a comparison feature, enabling you to make an informed and smart decision when purchasing a truck.
            </p>
            <p>With TruckMitr, you can compare different truck models, evaluate features, and make a well-informed purchase decision tailored to your needs. Explore our platform today and find the perfect truck for your business!</p>
            <a href="#" class="text-blue text-decoration-none">Read more</a>
            </div>
        </div>
        <div class="card p-3 mt-4 border">
            <div class="card-body mb-crd-body">
            <h4 class="title text-dark">Browse trucks by brands</h4>
            <div class="d-flex gap-2 my-3 flex-wrap mb-grid">
                     @if(isset($Brand))
                      @foreach($Brand as $value)
                    <div style="width:125px;" class="border p-3 rounded-4 d-flex flex-column align-items-center">
                    <img src="{{ url('public/'.$value->brand_images) }}"
                        alt="brand" width="75px"
                    />
                    <div class="text-center mt-2" style="font-size:13px;">{{$value->name}}</div>
                   </div>
                   @endforeach
                     @endif
            </div>
            <!--<a href="#" class="text-blue text-decoration-none">View all</a>-->
            </div>
        </div>
        </div>
    </div>
    </div>
</section>

<section class="my-5">
    <div class="container">
    <div class="row">
        <div class="col-12 col-md-4">
        <div class="card p-3 mt-4 border sticky-lg-top d-none d-md-block hght">
            <div class="card-body">
            <h4>Filters</h4>

            <div class="accordion" id="accordionPanelsStayOpenExample">
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#brandFilter"
                            aria-expanded="false" aria-controls="brandFilter">
                            <img src="{{url('public/assets/img/brand-n.png')}}" height="20px" />
                            <p><strong>Brand</strong></p>
                        </button>
                    </h2>
                    <div id="brandFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @if(isset($Trucklistcount))
                                @foreach($Trucklistcount as $brand)
                                <div class="form-check d-flex align-items-center">
                                    <input class="form-check-input truck-checkbox" type="checkbox" 
                                        value="{{$brand->bid}}" id="brandCheckbox{{$brand->bid}}" />
                                    <label class="form-check-label" for="brandCheckbox{{$brand->bid}}">
                                        {{$brand->name}} ({{$brand->truck_count}})
                                    </label>
                                </div>
                                @endforeach
                            @endif
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#budgetFilter"
                            aria-expanded="false" aria-controls="budgetFilter">
                            <img src="{{url('public/front/assets/images/tag.png')}}" height="20px" />
                            <p><strong>Budget</strong></p>
                        </button>
                    </h2>
                    <div id="budgetFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                           
                           
                            @foreach($Budget as $index => $budget)
                            <div class="form-check align-items-center gap-3">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $budget }}" id="budgetCheckbox{{ $index }}" />
                                <label class="form-check-label" for="budgetCheckbox{{ $index }}"> {{ $budget }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#fuelTypeFilter"
                            aria-expanded="false" aria-controls="fuelTypeFilter">
                            <img src="{{url('public/assets/img/fuel-n.png')}}" height="20px" />
                            <p><strong>Fuel Type</strong></p>
                        </button>
                    </h2>
                    <div id="fuelTypeFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                           
                            
                           @foreach ($Fueltype as $index => $fuelType)
                            <div class="form-check align-items-center gap-3">
                                <input 
                                    class="form-check-input truck-checkbox" 
                                    type="checkbox" 
                                    value="{{ $fuelType }}" 
                                    id="fuelTypeCheckbox{{ $index }}" 
                                />
                                <label 
                                    class="form-check-label" 
                                    for="fuelTypeCheckbox{{ $index }}">
                                    {{ $fuelType }}
                                </label>
                            </div>
                        @endforeach

                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#vehicleApplicationFilter"
                            aria-expanded="false" aria-controls="vehicleApplicationFilter">
                            <img src="{{url('public/assets/img/tyre.png')}}" height="20px" />
                            <p><strong>Vehicle Application</strong></p>
                        </button>
                    </h2>
                    <div id="vehicleApplicationFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            
                            @foreach($VehicleApplication as $index => $application)
                            <div class="form-check align-items-center gap-3">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $application }}" id="applicationCheckbox{{ $index }}" />
                                <label class="form-check-label" for="applicationCheckbox{{ $index }}">{{ $application }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#gvwFilter"
                            aria-expanded="false" aria-controls="gvwFilter">
                            <img src="{{url('public/assets/img/gvw.png')}}" height="20px" />
                            <p><strong>GVW (Tons)</strong></p>
                        </button>
                    </h2>
                    <div id="gvwFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                           
                            @foreach($Gvm as $index => $gvw)
                            <div class="form-check align-items-center gap-3">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $gvw }}" id="gvwCheckbox{{ $index }}" />
                                <label class="form-check-label" for="gvwCheckbox{{ $index }}">{{ $gvw }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#vehicleTypeFilter"
                            aria-expanded="false" aria-controls="vehicleTypeFilter">
                            <img src="{{url('public/assets/img/emission-new.png')}}" height="20px" />
                            <p><strong>Vehicle Type</strong></p>
                        </button>
                    </h2>
                    <div id="vehicleTypeFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                           
                            @foreach($Vehicletype as $index => $type)
                            <div class="form-check align-items-center gap-3">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $type }}" id="vehicleTypeCheckbox{{ $index }}" />
                                <label class="form-check-label" for="vehicleTypeCheckbox{{ $index }}">{{ $type }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#tyresCountFilter"
                            aria-expanded="false" aria-controls="tyresCountFilter">
                            <img src="{{url('public/assets/img/tyre.png')}}" height="20px" />
                            <p><strong>Tyres Count</strong></p>
                        </button>
                    </h2>
                    <div id="tyresCountFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                           
                            @foreach($TyresCount as $index => $count)
                            <div class="form-check align-items-center gap-3">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $count }}" id="tyresCountCheckbox{{ $index }}" />
                                <label class="form-check-label" for="tyresCountCheckbox{{ $index }}">{{ $count }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
            </div>
            </div>
        </div>
        
        <div class="d-md-none">
            <h4>Filters</h4>
            <button class="filters-btn sort" data-bs-toggle="collapse" data-bs-target="#accordionPanelsStayOpenExample" aria-expanded="false" aria-controls="accordionPanelsStayOpenExample">
                Filters
            </button>
            <div class="card p-0 mt-2 border absolute filterCard d-md-none collapse" id="accordionPanelsStayOpenExample">
            <div class="card-body">
        <!-- Filters Button (Visible on Mobile) -->

            <div class="accordion">
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#brandFilter"
                            aria-expanded="false" aria-controls="brandFilter">
                            <img src="{{url('public/assets/img/brand-n.png')}}" height="20px" />
                            <p><strong>Brand</strong></p>
                        </button>
                    </h2>
                    <div id="brandFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @if(isset($Trucklistcount))
                                @foreach($Trucklistcount as $brand)
                                <div class="form-check d-flex align-items-center gap-2">
                                    <input class="form-check-input truck-checkbox" type="checkbox" 
                                        value="{{$brand->bid}}" id="brandCheckbox{{$brand->bid}}" />
                                    <label class="form-check-label" for="brandCheckbox{{$brand->bid}}">
                                        {{$brand->name}} ({{$brand->truck_count}})
                                    </label>
                                </div>
                                @endforeach
                            @endif
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#budgetFilter"
                            aria-expanded="false" aria-controls="budgetFilter">
                            <img src="{{url('public/front/assets/images/tag.png')}}" height="20px" />
                            <p><strong>Budget</strong></p>
                        </button>
                    </h2>
                    <div id="budgetFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @php
                                $budgets = [
                                    'Below 10 lakhs', 
                                    '10 lakhs - 15 lakhs', 
                                    '15 lakhs - 20 lakhs', 
                                    '20 lakhs - 30 lakhs', 
                                    '30 lakhs - 40 lakhs', 
                                    '40 lakhs - 50 lakhs', 
                                    'Above 50 lakhs'
                                ];
                            @endphp
                            @foreach($budgets as $index => $budget)
                            <div class="form-check d-flex align-items-center gap-2">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $budget }}" id="budgetCheckbox{{ $index }}" />
                                <label class="form-check-label" for="budgetCheckbox{{ $index }}">{{ $budget }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#fuelTypeFilter"
                            aria-expanded="false" aria-controls="fuelTypeFilter">
                            <img src="{{url('public/assets/img/fuel-n.png')}}" height="20px" />
                            <p><strong>Fuel Type</strong></p>
                        </button>
                    </h2>
                    <div id="fuelTypeFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @php
                                $fuelTypes = ['Diesel', 'Petrol', 'CNG', 'EV', 'LNG'];
                            @endphp
                            @foreach($fuelTypes as $index => $fuelType)
                            <div class="form-check d-flex align-items-center gap-2">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $fuelType }}" id="fuelTypeCheckbox{{ $index }}" />
                                <label class="form-check-label" for="fuelTypeCheckbox{{ $index }}">{{ $fuelType }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#vehicleApplicationFilter"
                            aria-expanded="false" aria-controls="vehicleApplicationFilter">
                            <img src="{{url('public/assets/img/tyre.png')}}" height="20px" />
                            <p><strong>Vehicle Application</strong></p>
                        </button>
                    </h2>
                    <div id="vehicleApplicationFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @php
                                $applications = ['E-commerce', 'White Goods', 'Perishable', 'Livestock', 
                                                'Refrigerated Vehicles', 'Automobile Carrier', 
                                                'Construction Industry', 'Oversized', 'Fuel Tanker', 'Others'];
                            @endphp
                            @foreach($applications as $index => $application)
                            <div class="form-check d-flex align-items-center gap-2">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $application }}" id="applicationCheckbox{{ $index }}" />
                                <label class="form-check-label" for="applicationCheckbox{{ $index }}">{{ $application }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#gvwFilter"
                            aria-expanded="false" aria-controls="gvwFilter">
                            <img src="{{url('public/assets/img/gvw.png')}}" height="20px" />
                            <p><strong>GVW (Tons)</strong></p>
                        </button>
                    </h2>
                    <div id="gvwFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @php
                                $gvwRanges = ['11 - 19', '20 - 28', '29 - 40', '41 - 55'];
                            @endphp
                            @foreach($gvwRanges as $index => $gvw)
                            <div class="form-check d-flex align-items-center gap-2">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $gvw }}" id="gvwCheckbox{{ $index }}" />
                                <label class="form-check-label" for="gvwCheckbox{{ $index }}">{{ $gvw }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#vehicleTypeFilter"
                            aria-expanded="false" aria-controls="vehicleTypeFilter">
                            <img src="{{url('public/assets/img/emission-new.png')}}" height="20px" />
                            <p><strong>Vehicle Type</strong></p>
                        </button>
                    </h2>
                    <div id="vehicleTypeFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @php
                                $vehicleTypes = ['Trucks', 'Tippers', 'Trailers'];
                            @endphp
                            @foreach($vehicleTypes as $index => $type)
                            <div class="form-check d-flex align-items-center gap-2">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $type }}" id="vehicleTypeCheckbox{{ $index }}" />
                                <label class="form-check-label" for="vehicleTypeCheckbox{{ $index }}">{{ $type }}</label>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
                
                <div class="accordion-item border-0">
                    <h2 class="accordion-header">
                        <button class="accordion-button collapsed d-flex align-items-center gap-3 px-0"
                            type="button" data-bs-toggle="collapse" data-bs-target="#tyresCountFilter"
                            aria-expanded="false" aria-controls="tyresCountFilter">
                            <img src="{{url('public/assets/img/tyre.png')}}" height="20px" />
                            <p><strong>Tyres Count</strong></p>
                        </button>
                    </h2>
                    <div id="tyresCountFilter" class="accordion-collapse collapse">
                        <div class="accordion-body px-0">
                            @php
                                $tyresCounts = ['6 wheelers', '10 wheelers', '14 wheelers','16 wheelers', '18 wheelers', 'More than 18 wheelers'];
                            @endphp
                            @foreach($tyresCounts as $index => $count)
                            <div class="form-check d-flex align-items-center gap-2">
                                <input class="form-check-input truck-checkbox" type="checkbox" 
                                    value="{{ $count }}" id="tyresCountCheckbox{{ $index }}" />
                                <label class="form-check-label" for="tyresCountCheckbox{{ $index }}">{{ $count }}</label>
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
       <div class="col-12 col-md-8">
    <div class="d-block justify-content-between align-items-center mt-5 mb-4 my-md-4">
        <div class="row">
            <div class="col-md-8"><h4 id="truckcount">Available Trucks</h4></div>
            <div class="col-md-3">
                <select class="sorts">
                    <option value="">Sort by</option>
                    <option value="a-z">A-Z</option>
                    <option value="z-a">Z-A</option>
                    <option value="high-low">Price High to Low</option>
                    <option value="low-high">Price Low to High</option>
                    <option value="latest">Latest</option>
                </select>
            </div>
            <div class="col-md-1"></div>
        </div>
    </div>

    <div class="d-flex flex-wrap gap-4 pb-5 mb-5" id="searchfilter">
        @if(isset($Trucklist))
            @foreach($Trucklist as $value)
                <div class="cardlist card p-0 rounded-4">
                    <img style="height:180px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>
                    <div class="card-body text-center d-flex flex-column">
                        <h4 class="" style="font-size: 21px; line-height: 17px;">{{$value->oem_name}}</h4>
                         <h5 class="card-title">{{ Str::limit($value->Vehicle_model, 20) }}</h5>

                        <p class="card-text">₹{{$value->Price_Range}} - {{$value->max_price}} Lakhs*</p>

                        <div class="d-flex my-3 mb-4">
                            <div class="col-6">
                                <p class="text-gray">Wheel</p>
                                <p class="text-blue">{{ substr($value->Wheels, 0, 10) }}..</p>
                            </div>
                            <div class="col-6 border-start">
                                <p class="text-gray">ENGINE</p>
                                <p class="text-blue">{{$value->Engine_HP}}</p>
                            </div>
                        </div>
                        <a class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue mt-auto" 
                           href="{{url('product-details')}}/{{$value->slug}}">
                           Check Offers <i class="fa fa-long-arrow-right"></i>
                        </a>
                    </div>
                </div>
            @endforeach
        @endif

    </div>


<!--        <div class="d-flex justify-content-center my-5">-->
<!--    <nav>-->
<!--        <ul class="pagination">-->
<!--            @if ($Trucklist->onFirstPage())-->
<!--                <li class="page-item disabled">-->
<!--                    <span class="page-link">Previous</span>-->
<!--                </li>-->
<!--            @else-->
<!--                <li class="page-item">-->
<!--                    <a class="page-link" href="{{ $Trucklist->previousPageUrl() }}" aria-label="Previous">-->
<!--                        <span>&laquo; Previous</span>-->
<!--                    </a>-->
<!--                </li>-->
<!--            @endif-->

<!--            @foreach ($Trucklist->links()->elements[0] as $page => $url)-->
<!--                @if ($page == $Trucklist->currentPage())-->
<!--                    <li class="page-item active">-->
<!--                        <span class="page-link">{{ $page }}</span>-->
<!--                    </li>-->
<!--                @else-->
<!--                    <li class="page-item">-->
<!--                        <a class="page-link" href="{{ $url }}">{{ $page }}</a>-->
<!--                    </li>-->
<!--                @endif-->
<!--            @endforeach-->

<!--            @if ($Trucklist->hasMorePages())-->
<!--                <li class="page-item">-->
<!--                    <a class="page-link" href="{{ $Trucklist->nextPageUrl() }}" aria-label="Next">-->
<!--                        <span>Next &raquo;</span>-->
<!--                    </a>-->
<!--                </li>-->
<!--            @else-->
<!--                <li class="page-item disabled">-->
<!--                    <span class="page-link">Next</span>-->
<!--                </li>-->
<!--            @endif-->
<!--        </ul>-->
<!--    </nav>-->
<!--</div>-->
    <!-- Pagination -->
   

</div>

    </div>
    </div>
</section>



<script type="text/javascript">
    $(document).ready(function () {
       $('#brand').on('change', function () {
            var id = $('#brand').val();	
            console.log(id);
			$('#model').html('');
            var htmlg =  $('#model').html('');
            //console.log(htmlg)
            $.ajax({
                url: '{{url('allbrand') }}/'+id,
                type: 'get',
                success: function (res) {
                   // console.log(res);
				 $('.citydata').append(res);						
                }
            });
        });
	});
	
	function get_slug(){
	    var bid = $('#brand').val();	
	    var mid = $('#model').val();	
	    $.ajax({
	        url: "/get-slug",
            method: "POST",
            data: {
                _token: "{{ csrf_token() }}", // Include CSRF token if needed
                brands: bid,
                model: mid
            },
            success: function(data) {
               if(data!=''){
                   window.location.href = "/product-details/"+data;
               }
            },
            error: function(xhr, status, error) {
                console.error("Error:", error);
            }
	    })
	}

 
 function applyFilters(page = 1) {
    const selectedBrands = Array.from(document.querySelectorAll("#brandFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedBudgets = Array.from(document.querySelectorAll("#budgetFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedFuelTypes = Array.from(document.querySelectorAll("#fuelTypeFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedApplications = Array.from(document.querySelectorAll("#vehicleApplicationFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedGvws = Array.from(document.querySelectorAll("#gvwFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedVehicleTypes = Array.from(document.querySelectorAll("#vehicleTypeFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedTyresCounts = Array.from(document.querySelectorAll("#tyresCountFilter .truck-checkbox:checked"))
        .map((checkbox) => checkbox.value);

    const selectedSort = document.querySelector(".sorts").value;

    $.ajax({
        url: "/filter-trucks?page=" + page,
        method: "POST",
        data: {
            brands: selectedBrands,
            budgets: selectedBudgets,
            fuelTypes: selectedFuelTypes,
            applications: selectedApplications,
            gvws: selectedGvws,
            vehicleTypes: selectedVehicleTypes,
            tyresCounts: selectedTyresCounts,
            sort: selectedSort,
        },
        success: function (data) {
            $('#searchfilter').html(data);
            $('#pagination').html(data.pagination);
        },
        error: function (xhr, status, error) {
            console.error("Error:", error);
        }
    });
}

// Ensure event listeners are added after the function is defined
document.addEventListener("DOMContentLoaded", function () {
    const truckCheckboxes = document.querySelectorAll(".truck-checkbox");
    const sortDropdown = document.querySelector(".sorts");

    truckCheckboxes.forEach((checkbox) => {
        checkbox.addEventListener("change", () => {
            applyFilters(1);
        });
    });

    sortDropdown.addEventListener("change", () => {
        applyFilters(1);
    });

    $(document).on("click", "#pagination a", function (e) {
        e.preventDefault();
        let page = $(this).attr("href").split("page=")[1];
        applyFilters(page);
    });

    // Initial call
    applyFilters();
});
</script>


<script>
    $(document).ready(function() {
    $('#brand').select2(); // Ensure Select2 is properly initialized
});

</script>

<script>
    
</script>



<!-- FOOTER START HERE  -->
@include('Fronted.footer')
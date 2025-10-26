@if(isset($Trucklist) && $Trucklist->count() > 0)
    @foreach($Trucklist as $key => $value)
        <div class="carousel-item {{ $key == 0 ? 'active' : '' }}">
            <div class="cardlist card p-0 rounded-4">
                <img style="height:180px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="Truck Image" />

                <div class="card-body text-center">
                    
                    <h4 class="" style="font-size: 21px; line-height: 17px;">{{$value->oem_name}}</h4>
                    <h5 class="card-title">{{ Str::limit($value->Vehicle_model, 20) }}</h5>
                    <p class="card-text">₹{{ $value->Price_Range }} - {{ $value->max_price }} Lakh*</p>

                    <div class="d-flex my-3 mb-4">
                        <div class="col-6">
                            <p class="text-gray">Wheel</p>
                            <p class="text-blue">{{ Str::limit($value->Wheels, 15, '...') }}</p>
                        </div>
                        <div class="col-6 border-start">
                            <p class="text-gray">ENGINE</p>
                            <p class="text-blue">{{ $value->Engine_HP }}</p>
                        </div>
                    </div>

                    <a class="btn btn-outline-primary col-12 rounded-pill text-blue border-blue" href="{{ url('product-details/'.$value->slug) }}">
                        Check Offers <i class="fa fa-long-arrow-right"></i>
                    </a>
                </div>
            </div>
        </div>
    @endforeach
@else
    <p style="margin-left:44%">No trucks found!</p>
@endif
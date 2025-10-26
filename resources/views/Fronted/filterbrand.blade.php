
@if(isset($trucks))
@foreach($trucks as $value)
<div class="cardlist card p-0 rounded-4">
<img style="height:180px;" src="{{ url('public/'.$value->images) }}" class="card-img-top rounded-top-4" alt="..."/>

<div class="card-body text-center">
    <h5 class="card-title">
   
    <h4 class="" style="font-size: 21px; line-height: 17px;">{{$value->oem_name}}</h4>
    <h5 class="card-title">{{ Str::limit($value->Vehicle_model, 20) }}</h5>
     <p class="card-text">₹{{$value->Price_Range}} - {{$value->max_price}} Lakhs*</p>

    <div class="d-flex my-3 mb-4">
    <div class="col-6">
        <p class="text-gray">Wheel</p>
        <p class="text-blue"> <?php echo substr($value->Wheels, 0, 15); ?>..</p>
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

    <div class="d-flex justify-content-center my-5" id="pagination">
    <nav>
        <ul class="pagination">
            @if ($trucks->onFirstPage())
                <li class="page-item disabled">
                    <span class="page-link"><<</span>
                </li>
            @else
                <li class="page-item">
                    <a class="page-link" href="{{ $trucks->previousPageUrl() }}" aria-label="Previous">
                        <span> <<</span>
                    </a>
                </li>
            @endif

            @foreach ($trucks->links()->elements[0] as $page => $url)
                @if ($page == $trucks->currentPage())
                    <li class="page-item active">
                        <span class="page-link">{{ $page }}</span>
                    </li>
                @else
                    <li class="page-item">
                        <a class="page-link" href="{{ $url }}">{{ $page }}</a>
                    </li>
                @endif
            @endforeach

            @if ($trucks->hasMorePages())
                <li class="page-item">
                    <a class="page-link" href="{{ $trucks->nextPageUrl() }}" aria-label="Next">
                        <span>>></span>
                    </a>
                </li>
            @else
                <li class="page-item disabled">
                    <span class="page-link">>></span>
                </li>
            @endif
        </ul>
    </nav>
</div>
<script>
    document.getElementById('truckcount').innerHTML('truckcount');
</script>
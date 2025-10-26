@include('Fronted.header')
<style>
    .category {
    /*font-size: 20px;*/
    text-decoration: none;
    float: right;
    background: #52add9;
    color: #fff;
    padding: 1px 10px;
}

.blg-thmb {
  margin-top: 20px;
}

.cat-sd {
  color: #000 !important;
  border-bottom: 2px dotted;
  margin-bottom: 20px !important;
  font-size: 16px;
}

@media (max-width: 767px){
    .cat-sd {font-size: 14px;}
}
</style>
    <!-- BANNER SLIDER HERE  -->
    @if($blogs)
    <section class="py-5 blog-inner">
        <div class="container py-5 py5">
            <center>
                <div class="row">
                    <div class="col-lg-12 col-sm-12">
                        <h1 class="text-white">Blog</h1>
                        <ul class="breadcrumb text-white mt-3">
                            <li><a href="{{url('/')}}" class="text-white">Home</a></li>
                            <li><a href="{{url('blog')}}" class="text-white">Blog</a></li>
                            <li class="text-white">{{$blogs->name}}</li>
                        </ul>

                    </div>

                </div>
            </center>

        </div>

    </section>

  <section class="inner-blog py-3 py-md-5">
        <div class="container">
            <div class="row">

                <div class="col-lg-8 col-sm-12 col-xl-8">
                 <div class="blog-it mx-5 mx5">
                        <img src="{{ url('public/'.$blogs->images) }}" class="img-fluid">
                         <div class="row pt-3">
                            <div class="col-12 col-md-4"><span class="date-detail"><?php echo date('D-M-Y',strtotime($blogs->dates));?></span></div>
                            <div class="col-6 col-md-4"><span class="author"><i class="fa fa-user"></i>admin</span></div>
                            <div class="col-6 col-md-4"><a href="#" class="category">{{$blogs->category_name}}</a></div>
                        </div>
                        <h5 class="py-3">{{$blogs->name}}</h5>      

                        <p>{!! $blogs->description !!}</p>
                        
                       
                 </div>
                </div>


                <div class="col-lg-4 py-3 py-md-2 col-sm-12 col-xl-4 inner-image">
                    <h2>Recently Posted</h2>
                    <div>
                        @if(isset($blog))
                         @foreach($blog as $bg)
                         <div class="row p-2 pt-md-4">
                        <div class="col-lg-4 col-4 p-0">
                        <img src="{{ url('public/'.$bg->images) }}" class="img-fluid">
                        </div>
                        <div class="col-lg-8 col-8">
                        <p class="mb-2">{{$bg->name}} </p>
                        <a href="{{url('blog')}}/{{$bg->slug}}"> Read More </a>
                        </div>
                        </div>
                @endforeach
                @endif
                    </div>
                    <div class="category-blog-side py-4 py-md-5">
                        <h2>Categories</h2>
                         @if(isset($blog_cat))
                         @foreach($blog_cat as $bg)
                        <h6><a class="cat-sd" href="{{url('blogs')}}">{{$bg->category_name}}({{$bg->blog_count}})</a></h6>
                        @endforeach
                    @endif
                    </div>
                </div>

            </div>
        </div>
    </section>
    		@endif
@include('Fronted.footer')
@include('Fronted.header')

    <!-- BANNER SLIDER HERE  -->
<style>
    .category {
    font-size: 20px;
    text-decoration: none;
    float: right;
    background: #52add9;
    color: #fff;
    padding: 1px 10px;
}
</style>
    <section class="py-5 contact-bg blog">
        <div class="container py-5 py5">
            <center>
                <div class="row">
                    <div class="col-lg-12 col-sm-12">
                        <h1 class="text-white">Blog</h1>
                        <ul class="breadcrumb">
                            <li><a href="{{url('/')}}">Home</a></li>
                            <li class="text-white">Blog</li>
                        </ul>

                    </div>

                </div>
            </center>
        </div>

    </section>
  <section class="pb-5 pt-5">
    <div class="container">
        
      <div class="row">
           @if(isset($blog))
            @foreach($blog as $bg)
        <div class="col-lg-4 col-sm-4 blg">
             
              <div class="box-card">
                <img style="height:250px;" src="{{ url('public/'.$bg->images) }}" class="img-fluid blg-img">
               <span class="blog-span"><?php echo date('d-M-Y', strtotime($bg->dates)); ?></span>

                <div class="blog-set">
                   <div class="row cat">
                    <div class="col-sm-6"><span class="author"><i class="fa fa-user"></i>admin</span></div>
                    <div class="col-sm-6"><p class="category">{{$bg->category_name}}</p></div>
                </div>
                 <a class="link" href="{{url('blog')}}/{{$bg->slug}}">
                     <h5 class="title">{{$bg->name}}</h5>
                      <p class="title">
                        <?php echo substr($bg->description, 0, 200); ?>...
                      </p>
                </a>
                  <a class="link" href="{{url('blog')}}/{{$bg->slug}}"> Read More <i class="fa fa-long-arrow-right"></i></a>
                </div>

              </div>
            
            
           
            
        

        </div>
        @endforeach
            @endif
      </div>
       
    </div>
  </section>
    
@include('Fronted.footer')
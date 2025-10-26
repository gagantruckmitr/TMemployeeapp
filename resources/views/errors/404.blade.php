@include('Fronted.header')

    <style>
    
        .content-found {
            text-align: center;
            /*background: white;*/
            padding: 40px;
            border-radius: 10px;
            color:white;
       
        }
        .content-found h1 {
            font-size: 100px;
            color: #4a90e2;
        }
        .content-found h2 {
            font-size: 30px;
            color: white;
        }
        .content-found p {
            color: white;
            margin: 15px 0 30px;
        }
        .content-found a {
            text-decoration: none;
            background: #4a90e2;
            color: #fff;
            padding: 10px 20px;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .content-found a:hover {
            background: #357ABD;
        }
        nav.navbar.navbar-expand-lg.navbar-light.bg-white.p-0 {
    box-shadow: rgba(0, 0, 0, 0.16) 0px 1px 4px;
}
    </style>
<section class="py-5 newpage-bg about-us">
    <div class="container py-5 py5">
        <center>
            <div class="row">
                <div class="col-lg-12 col-sm-12">
                       <div class="content-found">
        <h1>404</h1>
        <h2>Oops! Page Not Found</h2>
        <p>The page you’re looking for doesn’t exist or has been moved.</p>
        <a href="{{ url('/') }}">← Go Back Home</a>
    </div>


                </div>

            </div>
        </center>
    </div>
</section>



@include('Fronted.footer')
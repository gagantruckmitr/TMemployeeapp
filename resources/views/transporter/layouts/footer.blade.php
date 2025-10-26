<footer>
                <p>© 2025 TruckMitr Corporate Services Private Limited. All Rights Reserved.</p>
            </footer>
        </div>
    </div>

    <script src="{{url('public/assets/js/jquery-3.6.0.min.js')}}"></script>
    <script src="{{url('public/assets/plugins/bootstrap/js/bootstrap.bundle.min.js')}}"></script>
    <script src="{{url('public/assets/js/feather.min.js')}}"></script>
    <script src="{{ URL('public/assets/plugins/bootstrap-tagsinput/js/bootstrap-tagsinput.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/apexchart/chart-data.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/datatables/datatables.min.js') }}"></script>
    <script src="{{url('public/assets/plugins/slimscroll/jquery.slimscroll.min.js')}}"></script>
    <script src="{{url('public/assets/plugins/apexchart/apexcharts.min.js')}}"></script>
    <script src="{{url('public/assets/plugins/apexchart/chart-data.js')}}"></script>
    <script src="{{url('public/assets/js/script.js')}}"></script>
    <script src="{{url('public/common.js')}}"></script>
    
    <script>
		ClassicEditor
	    .create( document.querySelector( '#features' ) )
	    .then( description => {
	        console.log( features );
	    })
	    .catch( error => {
	        console.error( error );
	    });

		ClassicEditor
	    .create( document.querySelector( '#feature' ) )
	    .then( description => {
	        console.log( features );
	    })
	    .catch( error => {
	        console.error( error );
	    });

	</script>
	
</body>

</html>
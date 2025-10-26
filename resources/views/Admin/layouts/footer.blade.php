<footer>
                <p>© 2025 TruckMitr Corporate Services Private Limited. All Rights Reserved.</p>
            </footer>
        </div>
    </div>

    <script src="{{ URL('public/assets/plugins/bootstrap/js/bootstrap.bundle.min.js') }}"></script>
    <script src="{{ URL('public/assets/js/feather.min.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/slimscroll/jquery.slimscroll.min.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/apexchart/apexcharts.min.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/select2/js/select2.min.js') }}"></script>
    <script src="{{ URL('public/assets/js/ckeditor.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/bootstrap-tagsinput/js/bootstrap-tagsinput.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/apexchart/chart-data.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/datatables/datatables.min.js') }}"></script>
    <script src="{{ URL('public/assets/js/script.js') }}"></script>
   
    <script src="{{ URL('public/assets/plugins/lightbox/glightbox.min.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/lightbox/lightbox.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/toastr/toastr.min.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/toastr/toastr.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/sweetalert/sweetalert2.all.min.js') }}"></script>
    <script src="{{ URL('public/assets/plugins/sweetalert/sweetalerts.min.js') }}"></script>
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
	
	<script>
ClassicEditor
    .create(document.querySelector('#message'), {
        ckfinder: {
            uploadUrl: "{{ route('admin.popup-messages.ckeditor.upload') }}?_token={{ csrf_token() }}"
        }
        
    })
    .catch(error => {
        console.error(error);
    });
</script>
	
</body>

</html>
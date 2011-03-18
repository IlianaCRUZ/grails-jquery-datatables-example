Install some plugins:

	grails install-plugin jquery
	grails install-plugin jquery-ui
	grails install-plugin jquery-datatables

Add the following to the <head> of your grails-app/views/layouts/main.gsp:

	<g:javascript library="jquery" plugin="jquery" />
	<jqui:resources />

Add the following to grails-app/conf/Config.groovy:

	grails.views.javascript.library="jquery"

Create a Person domain class with firstName, lastName, and birthDate properties:

	class Person {
		String firstName
		String lastName
		Date birthDate
		
		Date dateCreated
		Date lastUpdated
		
	    static constraints = {
			birthDate(nullable:true)
	    }
	}
	
Populate some instances at startup in grails-app/conf/BootStrap.groovy:

	private def createPerson(properties) {
		def person = Person.findByFirstNameAndLastName(properties.firstName, properties.lastName)
		if ( ! person ) {
			person = new Person(properties)
			if ( ! person.save() ) {
				println "Unable to save person: ${person.errors}"
			}
		}
	}
	
    def init = { servletContext ->
		createPerson([firstName: 'John', lastName: 'Doe', birthDate: Date.parse('yyyy-MM-dd', '1980-01-06')])
		createPerson([firstName: 'Jane', lastName: 'Doe', birthDate: Date.parse('yyyy-MM-dd', '1981-02-05')])
		createPerson([firstName: 'Ben', lastName: 'Dover', birthDate: Date.parse('yyyy-MM-dd', '1982-03-04')])
		createPerson([firstName: 'Seymour', lastName: 'Butts', birthDate: Date.parse('yyyy-MM-dd', '1983-04-03')])
		createPerson([firstName: 'Hugh', lastName: 'Jass', birthDate: Date.parse('yyyy-MM-dd', '1984-05-02')])
		createPerson([firstName: 'Dixie', lastName: 'Normus', birthDate: Date.parse('yyyy-MM-dd', '1985-06-01')])
    }	

Create PersonController, and add index and dataTablesData actions:

	def index = {
			
	}
	
	def dataTablesData = {
		def propertiesToRender = ['id', 'firstName', 'lastName', 'birthDate']
	
		def dataToRender = [:]
		dataToRender.sEcho = params.sEcho
		dataToRender.aaData=[]                // Array of people.
	
		dataToRender.iTotalRecords = Person.count()
		dataToRender.iTotalDisplayRecords = dataToRender.iTotalRecords
	
		// Create the query, possibly with a search filters. We only search
		// String properties in this example.
		def filters = []
		filters << "p.firstName like :filter"
		filters << "p.lastName like :filter"
		
		def filter = filters.join(" OR ")
		def query = new StringBuilder("from Person as p")
		if ( params.sSearch ) {
		   query.append(" where (${filter})")
		}
		query.append(" order by p.${propertiesToRender[params.iSortCol_0 as int]} ${params.sSortDir_0}")
	
		// Execute the query
		def people = []
		if ( params.sSearch ) {
		   // Revise the number of total display records after applying the filter
		   def countQuery = new StringBuilder("select count(*) from Person as p where (${filter})")
		   def result = Person.executeQuery(countQuery.toString(),
											 [filter: "%${params.sSearch}%"])
		   if ( result ) {
			  dataToRender.iTotalDisplayRecords = result[0]
		   }
		   people = Person.findAll(query.toString(),
			  [filter: "%${params.sSearch}%"],
			  [max: params.iDisplayLength as int, offset: params.iDisplayStart as int])
		} else {
		   people = Person.findAll(query.toString(),
		   [max: params.iDisplayLength as int, offset: params.iDisplayStart as int])
		}
	
		// Process the response
		people?.each { person ->
		   def record = []
		   propertiesToRender.each { record << person."${it}" }
		   dataToRender.aaData << record
		}
	
		render dataToRender as JSON	
	}

Create the grails-app/views/person/index.gsp:

	<html>
	 <head>
	 <meta name="layout" content="main" />
	 <title>People</title>
	 <jqDT:resources />
	 <g:javascript>
	
	    $(document).ready(function() {
	       $('#people').dataTable({
	          sScrollY: '70%',
	          bProcessing: true,
	          bServerSide: true,
	          sAjaxSource: '${request.contextPath + '/person/dataTablesData'}' ,
	          sPaginationType: "full_numbers",
	          aLengthMenu: [[100, 500, 1000, 5000, -1], [100, 500, 1000, 5000, "All"]],
	          iDisplayLength: 500
	       });
	    });
	 </g:javascript>
	
	 </head>
	
	 <body>
	
		<table id="people">
		<thead>
		   <tr>
		      <th>Id</th>
		      <th>First Name</th>
		      <th>Last Name</th>
		      <th>Birth Date</th>
		   </tr>
		</thead>
		<tbody></tbody>
		<tfoot>
		   <tr>
		      <th>Id</th>
		      <th>First Name</th>
		      <th>Last Name</th>
		      <th>Birth Date</th>
		   </tr>
		</tfoot>
		</table>
	
	 </body>
	</html>

Start the app and verify you can see the list of people at
http://localhost:8080/grails-jquery-datatables-example/person/. Play around with
searching and sorting by columns.

Implement the PersonController show action to render a JSON response (you'll
need to add imports for the JSON and XML converters):

	def show = {
		def person = Person.get(params.id as int)
		
		if ( ! person ) {
			render(text: "No person with id ${params.id} found", status: 404)
		} else {
			withFormat {
				json {
					if ( params.callback ) {
						render(contentType: 'application/json',
							   text: "${params.callback}(${person as JSON})")	
					} else {
						render person as JSON
					}
				}
				xml {
					render person as XML
				}
			}
		}
	}

Hide the Id column. We only included it because we can use it to get more
information from the database. Back in grails-app/views/person/index.gsp add
the aoColumns property to your call to .dataTable():

	aoColumns: [
		/* Id */         {bVisible: false},
	  	/* First Name */ null,
	  	/* Last Name */  null,
	  	/* Birth Date */ null
	]
          

Add a row click handler to each row that gets the row's id, and makes an Ajax call to
the PersonController show action to get the data for the row that was clicked on.
Back in grails-app/views/person/index.gsp add the fnRowCallback property to your
call to .dataTable():

	  fnRowCallback: function(nRow, aData, iDisplayIndex) {
	  	$(nRow).click(function(){
	  		var id = aData[0];
			$.ajax({
				dataType: 'json',
				url: '${request.contextPath + '/person/show/'}' + id + '.json',
				success: function(data, status, xhr) {
					// TODO: we'll modify this next to create and display
					// a jQuery dialog using the data
					alert(JSON.stringify(data, null));
				},
				error: function(xhr, status, err) { },
				complete: function(xhr, status) { }
			});
	  	});
	  	return nRow;
	  }
          
Use the response from the PersonController show action to create
(and display) a jQuery dialog. Modify the ajax success callback function:

	function(data, status, xhr) {
		var dl = $('<dl class="personDetails"></dl>')
					.append('<dt>Id:</dt><dd>' + data.id +'</dd>')
					.append('<dt>First name:</dt><dd>' + data.firstName +'</dd>')
					.append('<dt>Last name:</dt><dd>' + data.lastName +'</dd>')
					.append('<dt>Birth date:</dt><dd>' + data.birthDate + '</dd>')
					.append('<dt>Date created:</dt><dd>' + data.dateCreated + '</dd>')
					.append('<dt>Last updated:</dt><dd>' + data.lastUpdated + '</dd>');
		
		$('<div></div>')
			.append(dl)
			.dialog({
				modal: true
			});
	}
	
Of course, feel free to create the dialog contents however you wish, and to style
it appropriately.


TODO: Optimize by caching responses in (and fetching from) HTML5 localStorage


You can download the source code from GitHub at:

	git://github.com/erturne/grails-jquery-datatables-example.git

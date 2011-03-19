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
          sAjaxSource: '${request.contextPath + '/people/dataTablesData'}' ,
          sPaginationType: "full_numbers",
          aLengthMenu: [[100, 500, 1000, 5000, -1], [100, 500, 1000, 5000, "All"]],
          iDisplayLength: 500,
          aoColumns: [
          	/* Id */         {bVisible: false},
          	/* First Name */ null,
          	/* Last Name */  null,
          	/* Birth Date */ null
          ],
          fnRowCallback: function(nRow, aData, iDisplayIndex) {
          	$(nRow).click(function(){
          		var id = aData[0];
				$.ajax({
					dataType: 'json',
					url: '${request.contextPath + '/people/'}' + id + '.json',
					success: function(data, status, xhr) {
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
					},
					error: function(xhr, status, err) { },
					complete: function(xhr, status) { }
				});
          	});
          	return nRow;
          }
       });
    });
 </g:javascript>
 <link type="text/css" href="${resource(dir:'css',file:'personDetail.css')}" />
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

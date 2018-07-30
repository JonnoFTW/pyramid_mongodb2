<%
    import pprint
    pp = pprint.PrettyPrinter(indent=2, compact=True)
    from bson import json_util
    def sizeof_fmt(num, suffix='B'):
        for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
            if abs(num) < 1024.0:
                return "%3.1f %s%s" % (num, unit, suffix)
            num /= 1024.0
        return "%.1f %s%s" % (num, 'Yi', suffix)
%>
<!-- Modal -->
<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span>
                </button>
                <h5 class="modal-title" id="myModalLabel">Cursor Explanation</h5>
            </div>
            <div class="modal-body">
                <h4>Query:</h4>
                <pre id="modal-cursor-query" style="white-space: pre-wrap"></pre>
                <h4>Explain()</h4>
                <pre id="modal-cursor-explanation">

                </pre>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>
<div class="modal fade" id="modalDetails" tabindex="-1" role="dialog" aria-labelledby="modalDetailsLabel">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span>
                </button>
                <h5 class="modal-title" id="modalDetailsLabel">Collection Attribute Details</h5>
            </div>
            <div class="modal-body">
                <h4 id="modal-coll-attr">Field:</h4>
                <h3>Details</h3>
                <pre id="modal-coll-detail"></pre>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>
<div>
    <ul class="nav nav-tabs" role="tablist">
        <li role="presentation" class="active" ><a href="#queries" aria-controls="queries" data-toggle="tab" aria-expanded="true">Queries</a>
        </li>
        <li role="presentation"><a href="#connection" aria-controls="connection" data-toggle="tab">Connection</a></li>
        <li role="presentation"><a href="#collections" aria-controls="collections" data-toggle="tab">Collections</a>
        </li>
    </ul>
</div>
<div class="tab-content">
    <div role="tabpanel" class="tab-pane fade in active" id="queries">
        <table class="pDebugSortable table table-striped table-condensed tablesorter tablesorter-bootstrap table-bordered">
            <thead>
            <tr>
                % for h in 'Seq','Duration','Database.Collection', 'Operation', 'Args', 'Kwargs', 'Explain':
                    <th>${h}</th>
                % endfor
            </tr>
            </thead>
            <tbody>
                % for idx, q in enumerate(request.query_log):
                    <tr>
                        <td>${idx}</td>
                        <td>${round(q['duration'].total_seconds()*1000, 2)} ms</td>
                        <td>${'<a href="#{0}" class="show-coll">{0}</a>.<a href="#{0}-{1}" class="show-coll">{1}</a>'.format(*q['collection'].full_name.split('.'))|n}</td>
                        <td>
                            <a href="http://api.mongodb.com/python/current/api/pymongo/collection.html#pymongo.collection.Collection.${q['op']}">${q['op']}</a>
                        </td>
                        <td>${', '.join(repr(x) for x in q['args'])}</td>
                        <td>${q['kwargs']}</td>
                        <td>
                            %if 'cursor' in q:
                                <button type="button"
                                        class="btn btn-primary btn-sm"
                                        data-toggle="modal"
                                        data-query="${q['collection'].full_name}.${q['op']}(${('\n    '+(', '.join(pprint.pformat(x) for x in q['args'])))}, ${', '.join("{}={}".format(k,repr(v)) for k,v in q['kwargs'].items())})"
                                        data-server="${q['cursor'].address}"
                                        data-expl='${json_util.dumps(q['cursor'].explain(), indent=4)}'
                                        data-target="#myModal"
                                >
                                    Explain
                                </button>
                            %endif
                        </td>
                    </tr>
                % endfor
            <tr>
                <td><b>Total</b></td>
                <td><b>${round(sum(x['duration'].total_seconds()*1000 for x in request.query_log),2)} ms</b></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
            </tr>
            </tbody>
        </table>
    </div>
    <div role="tabpanel" class="tab-pane fade" id="connection">
        <table class="table table-striped table-condensed table-bordered">
            <thead>
            <tr>
                <th>Field</th>
                <th>Value</th>
            </tr>
            </thead>
            <tbody>
                %for h in  'address','primary', 'secondaries', 'arbiters','is_primary', 'is_mongos', 'max_pool_size', 'min_pool_size','max_idle_time_ms','nodes', 'max_bson_size', 'max_message_size', 'max_write_batch_size', 'local_threshold_ms', 'server_selection_timeout', 'codec_options', 'read_preference', 'write_concern', 'read_concern', 'is_locked' :
                    <tr>
                        <td><a target="_blank"
                               href="https://api.mongodb.com/python/current/api/pymongo/mongo_client.html#pymongo.mongo_client.MongoClient.${h}">${h.replace('_', ' ').title()}</a>
                        </td>
                        <td>
                            <%
                                try:
                                    res = getattr(request.db, h)
                                except:
                                    res = "Error"
                            %>
                            ${res}
                        </td>
                    </tr>
                %endfor

            </tbody>
        </table>
    </div>
    <div role="tabpanel" class="tab-pane" id="collections">
        % for db in set(x['db'].name for x in request.query_log):
            <span id="${db}" style="display: block;  height: 50px; margin-top: -50px; visibility: hidden;"></span>
            <h3>Database: <b><a href="#${db}">${db}</a></b></h3>
        <%
            try:
                stats = request.db[db].command('dbstats')
            except Exception as e:
                stats = None
                err = e
        %>
        %if stats:

            <table class="table table-striped table-condensed table-bordered">
                <tbody>
                    % for k,v in stats.items():
                        <tr>
                            <td class="col-md-2">${k}</td>
                            <td>
                                %if k.endswith('Size'):
                                    ${sizeof_fmt(v)}
                                %else:
                                    ${v}
                                %endif

                            </td>
                        </tr>
                    % endfor
                </tbody>
            </table>
        %else:
            <p>Error getting dbstats, you may not have relevant permissions</p>
            <pre>${err}</pre>
        %endif
            <h3>Collections</h3>
        % for collection in request.db[db].list_collections():
            <span id="${db}-${collection['name']}"
                  style="display: block;  height: 50px; margin-top: -50px; visibility: hidden;"></span>
            <h4><a href="#${db}-${collection['name']}">${collection['name']}</a></h4>
        <%
            try:
                collstats = request.db[db].command('collstats', collection['name'])
            except Exception as e:
                collstats = None
                err = e
        %>
        % if collstats:

            <table class="table table-striped table-condensed table-bordered">
                <tbody>
                    % for k,v in collstats.items():
                        <tr>
                            <td class="col-md-2">${k}</td>
                            <td>
                                %if k.endswith('Size'):
                                    ${sizeof_fmt(v)}
                                %elif k.endswith('Sizes'):
                                    % for idxname, size in v.items():
                                        <b>${idxname}</b>: ${sizeof_fmt(size)}<br>
                                    % endfor
                                %elif type(v) is dict:
                                    <button type="button"
                                            class="btn btn-primary btn-sm"
                                            data-toggle="modal"
                                            data-query="${k}"
                                            data-expl='${json_util.dumps(v)}'
                                            data-target="#modalDetails"
                                    >
                                        Show
                                    </button>
                                %else:
                                    ${v}
                                %endif
                            </td>
                        </tr>
                    % endfor
                </tbody>
            </table>
        %else:
            <p>Error getting collstats, you may not have relevant permissions</p>
            <pre>${err}</pre>
        % endif
        % endfor

        % endfor


    </div>
</div>


<script type="text/javascript">
    $('#myModal').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget);
        var expl = button.data('expl');
        var query = button.data('query');
        var modal = $(this);
        modal.find('#modal-cursor-query').text(query);
        modal.find('#modal-cursor-explanation').text(JSON.stringify(expl, null, 4));
    });
    $('#modalDetails').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget);
        var expl = button.data('expl');
        var query = button.data('query');
        var modal = $(this);
        modal.find('#modal-coll-attr').text(query);
        modal.find('#modal-coll-detail').text(JSON.stringify(expl, null, 4));
    });
    $('.show-coll').click(function (e) {
        $('ul.nav a[href="#collections"]').tab('show');
    });
    $('a[href="#collections"]').on('shown.bs.tab', function (e) {
        $('html,body').animate({scrollTop: $(window.location.hash).offset().top}, 500);
    })
</script>
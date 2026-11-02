"""Offline injected boundary cases against unchanged source; never live API claims."""
import importlib.util,io,json,os,ssl,unittest,urllib.error
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('target',ROOT/'source/tavily/scripts/tavily_search.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Response:
 def __init__(self,body):self.body=body
 def __enter__(self):return self
 def __exit__(self,*args):pass
 def read(self,n):return self.body[:n]
class Boundaries(unittest.TestCase):
 def call(self,**kw):
  return m.tavily_search(query=kw.pop('query','test'),max_results=3,include_answer=False,search_depth='basic',**kw)
 def test_request_contract(self):
  def fake(req,**kwargs):
   self.assertEqual(req.full_url,'https://api.tavily.com/search');self.assertEqual(req.method,'POST')
   self.assertEqual(req.get_header('Authorization'),'Bearer synthetic-test-key')
   body=json.loads(req.data);self.assertEqual(body['include_domains'],['docs.python.org']);self.assertFalse(body['include_raw_content'])
   return Response(b'{"results":[{"title":"T","url":"https://docs.python.org/","content":"C","score":0.8}]}')
  with patch.dict(os.environ,{'TAVILY_API_KEY':'synthetic-test-key'}),patch.object(m.urllib.request,'urlopen',side_effect=fake):
   self.assertEqual(m.to_brave_like(self.call(include_domains=[' Docs.Python.org ','docs.python.org']))['results'][0]['snippet'],'C')
 def test_401(self):
  self.assertEqual(m._http_error_message(urllib.error.HTTPError(m.TAVILY_URL,401,'',{},io.BytesIO(b''))),'Tavily authentication failed; check TAVILY_API_KEY')
 def test_429(self):
  self.assertEqual(m._http_error_message(urllib.error.HTTPError(m.TAVILY_URL,429,'',{},io.BytesIO(b''))),'Tavily rate limit or credit quota exceeded')
 def test_500(self):
  self.assertIn('HTTP 500: unavailable',m._http_error_message(urllib.error.HTTPError(m.TAVILY_URL,500,'',{},io.BytesIO(b'{"message":"unavailable"}'))))
 def test_invalid_json(self):
  with patch.object(m.urllib.request,'urlopen',return_value=Response(b'not json')):
   with self.assertRaisesRegex(m.TavilySearchError,'invalid JSON'):m._request_json(None,1)
 def test_nonobject_json(self):
  with patch.object(m.urllib.request,'urlopen',return_value=Response(b'[]')):
   with self.assertRaisesRegex(m.TavilySearchError,'unexpected JSON'):m._request_json(None,1)
 def test_response_size(self):
  with self.assertRaisesRegex(m.TavilySearchError,'safety limit'):m._read_bounded(Response(b'x'*(m.MAX_RESPONSE_BYTES+1)))
 def test_network_error(self):
  with patch.object(m.urllib.request,'urlopen',side_effect=urllib.error.URLError('injected network error')):
   with self.assertRaisesRegex(m.TavilySearchError,'Unable to reach Tavily'):m._request_json(None,1)
 def test_tls_error(self):
  with patch.object(m.urllib.request,'urlopen',side_effect=urllib.error.URLError(ssl.SSLCertVerificationError('injected'))),patch.object(m,'_certifi_context',return_value=None):
   with self.assertRaisesRegex(m.TavilySearchError,'certificate verification was not disabled'):m._request_json(None,1)
 def test_empty_query(self):
  with self.assertRaisesRegex(m.TavilySearchError,'must not be empty'):self.call(query=' ')
 def test_country_topic(self):
  with self.assertRaisesRegex(m.TavilySearchError,'general topic'):self.call(topic='news',country='china')
 def test_domain_limit(self):
  with self.assertRaisesRegex(m.TavilySearchError,'maximum is 300'):m._clean_domains([str(i) for i in range(301)],300)
if __name__=='__main__':
 stream=io.StringIO();res=unittest.TextTestRunner(stream=stream,verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Boundaries))
 record={'kind':'offline simulated transport/unit boundary tests, not live Tavily responses','testsRun':res.testsRun,'failures':len(res.failures),'errors':len(res.errors),'passed':res.wasSuccessful(),'log':stream.getvalue()}
 # Results go to stdout; archived evidence is never overwritten.
 print(record['log']);raise SystemExit(0 if res.wasSuccessful() else 1)

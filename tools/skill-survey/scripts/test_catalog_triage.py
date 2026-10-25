import unittest
from catalog_triage import screen

class ScreeningBoundaryTests(unittest.TestCase):
    def test_platform_claim_wins_over_prompt_only_claim(self):
        result = screen({'summary':'A prompt-only helper', 'metadata':{'os':['darwin']}})
        self.assertEqual(result['screening_signal'],'L3线索')
        self.assertIn('非源码分级',result['screening_status'])

    def test_absence_of_clues_does_not_imply_l1(self):
        self.assertEqual(screen({'summary':'Helpful assistant'})['screening_signal'],'摘要证据不足')

    def test_explicit_text_only_is_only_a_clue(self):
        result = screen({'summary':'Text-only reasoning, no tools required'})
        self.assertEqual(result['screening_signal'],'L1线索')
        self.assertNotIn('portability',result)

    def test_word_boundaries_do_not_match_node_in_knowledge(self):
        result=screen({'summary':'Knowledge and methodology'})
        self.assertFalse(any(c['kind']=='运行时或外部工具' for c in result['screening_clues']))

    def test_setup_values_do_not_become_execution_claims(self):
        result=screen({'summary':'Guidance', 'metadata':{'setup':[{'key':'API_KEY','required':False}]}})
        self.assertEqual(result['screening_signal'],'摘要证据不足')

    def test_non_ascii_and_empty_metadata(self):
        result=screen({'summary':'纯提示词教学', 'metadata':None})
        self.assertEqual(result['screening_signal'],'L1线索')
        self.assertEqual(result['functional_category'],'科研与教学')

if __name__=='__main__':
    unittest.main()

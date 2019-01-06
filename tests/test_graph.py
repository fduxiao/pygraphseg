import pygraphseg
import unittest
import random


class TestGraph(unittest.TestCase):
    def setUp(self):
        self.target = random.randint(10, 20)
        self.arr = [
            [[self.target, 2, 3], [10, 20, 11], [4, 5, 6]],
            [[7, 8, 9], [13, 17, 19], [99, 98, 97]],
        ]
        self.vertex = []
        for y, line in enumerate(self.arr):
            for x, pix in enumerate(line):
                self.vertex.append((x, y, *pix))

    def test_graph(self):
        # noinspection PyUnresolvedReferences
        graph = pygraphseg.Graph(self.arr).graph
        width, height, channel_size = graph.shape
        self.assertEqual(width, 3)
        self.assertEqual(height, 2)
        self.assertEqual(channel_size, 3)
        vertex = graph.vertex
        self.assertListEqual(vertex, self.vertex)

    def test_reuse(self):
        # noinspection PyUnresolvedReferences
        graph = pygraphseg.Graph(self.arr)
        addr1 = graph.graph_id
        self.arr[0][0][1] = 3
        graph.renew_graph(self.arr)
        addr2 = graph.graph_id
        self.assertEqual(addr1, addr2)

        graph.renew_graph([[[self.target]]])
        '''
        this should not always be different
        '''
        # addr3 = graph.graph_id
        # self.assertNotEqual(addr2, addr3)
        self.assertEqual(graph.graph.width, 1)
        self.assertEqual(graph.graph.height, 1)
        self.assertEqual(graph.graph.channel_length, 1)

    def test_sort(self):
        # noinspection PyUnresolvedReferences
        graph = pygraphseg.Graph(self.arr).sort().graph
        edges = graph.edges
        ws = list()
        for i, j, w in edges:
            # self.assertEqual(w, 0)
            ws.append(w)
        self.assertListEqual(ws, list(sorted(ws)))

    def test_segment(self):
        # noinspection PyUnresolvedReferences
        segments = pygraphseg.Graph(self.arr).segment(1).get_segments()
        print(segments)


if __name__ == '__main__':
    unittest.main()

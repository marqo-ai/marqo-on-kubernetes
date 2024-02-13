import os
import marqo
from marqo.models.marqo_index import *

mq = marqo.Client(f'http://{os.environ["MARQO_CLUSTER_IP"]}:8882')

mq.create_index(
    'my_unstructured_index_1',
    type=IndexType.Unstructured,
    model='ViT-B/16'
)

mq.index('my_unstructured_index_1').add_documents(
    [
        {
            '_id': 'doc3',
            'title': 'Marqo',
            'content': "Marqo is more than a vector database, it's an end-to-end vector search engine. Vector generation, storage and retrieval are handled out of the box through a single API. No need to bring your own embeddings.",
            'tags': ['vector_search', 'multimodal'],
            'price': 980.8,
            'image': 'https://docs.marqo.ai/1.4.0/assets/logo.png',
        }
    ],
    mappings={
        'title_image': {
            'type': 'multimodal_combination',
            'weights': {
                'title': 0.1,
                'image': 0.9
            }
        }
    },
    tensor_fields=['title_image', 'content']
)
print('Document added')
print('Searching for "Information retrieval"')
result = mq.index('my_unstructured_index_1').search('Information retrieval', filter_string='tags:multimodal')
print(result)
